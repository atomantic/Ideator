#!/bin/bash

# sync-packs.sh
# Syncs all prompt packs from IdeatorPromptPacks repository to the Ideator app
# Usage: ./sync-packs.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IDEATOR_PACKS_DIR="../IdeatorPromptPacks"
SOURCE_DIR="$IDEATOR_PACKS_DIR/packs"
DEST_DIR="$SCRIPT_DIR/Ideator/Resources/PromptPacks"

echo "🔄 Prompt Packs Sync Script"
echo "=========================="

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ Error: IdeatorPromptPacks/packs directory not found at $SOURCE_DIR${NC}"
    echo "Please ensure IdeatorPromptPacks is cloned in the parent directory"
    exit 1
fi

echo ""
echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"
echo ""

# Sync each pack
for pack_dir in "$SOURCE_DIR"/*/; do
    pack_id=$(basename "$pack_dir")

    # Map directory names to destination folder names (Core is capitalized)
    if [ "$pack_id" = "core" ]; then
        dest_pack_dir="$DEST_DIR/Core"
    else
        dest_pack_dir="$DEST_DIR/$pack_id"
    fi

    mkdir -p "$dest_pack_dir"

    # Copy TSV files
    tsv_count=0
    for tsv_file in "$pack_dir"*.tsv; do
        [ -f "$tsv_file" ] || continue
        cp "$tsv_file" "$dest_pack_dir/"
        tsv_count=$((tsv_count + 1))
    done

    # Copy manifest.json as {packId}-manifest.json to avoid Xcode flat-bundle collision
    if [ -f "$pack_dir/manifest.json" ]; then
        cp "$pack_dir/manifest.json" "$dest_pack_dir/${pack_id}-manifest.json"
    fi

    source_version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$pack_dir/manifest.json" | grep -o '"[^"]*"$' | tr -d '"')
    echo -e "  ${GREEN}✅${NC} $pack_id v$source_version ($tsv_count TSV files)"
done

echo ""
echo "📊 Git status:"
cd "$SCRIPT_DIR"
git status --short Ideator/Resources/PromptPacks/

echo ""
echo -e "${GREEN}✅ All packs synced!${NC}"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff Ideator/Resources/PromptPacks/"
echo "2. Test the app"
echo "3. Commit when ready"

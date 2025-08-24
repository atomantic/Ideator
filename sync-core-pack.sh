#!/bin/bash

# sync-core-pack.sh
# Syncs the core prompt pack from IdeatorPromptPacks repository to the Ideator app
# Usage: ./sync-core-pack.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IDEATOR_PACKS_DIR="../IdeatorPromptPacks"
SOURCE_PACK_DIR="$IDEATOR_PACKS_DIR/packs/core"
DEST_PACK_DIR="$SCRIPT_DIR/Ideator/Resources/PromptPacks/Core"

echo "🔄 Core Pack Sync Script"
echo "========================"

# Check if IdeatorPromptPacks exists
if [ ! -d "$IDEATOR_PACKS_DIR" ]; then
    echo -e "${RED}❌ Error: IdeatorPromptPacks directory not found at $IDEATOR_PACKS_DIR${NC}"
    echo "Please ensure IdeatorPromptPacks is cloned in the parent directory"
    exit 1
fi

# Check if source core pack exists
if [ ! -d "$SOURCE_PACK_DIR" ]; then
    echo -e "${RED}❌ Error: Core pack not found at $SOURCE_PACK_DIR${NC}"
    exit 1
fi

# Check if destination directory exists
if [ ! -d "$DEST_PACK_DIR" ]; then
    echo -e "${YELLOW}⚠️  Warning: Destination directory not found at $DEST_PACK_DIR${NC}"
    echo "Creating destination directory..."
    mkdir -p "$DEST_PACK_DIR"
fi

# Get version from source manifest
if [ -f "$SOURCE_PACK_DIR/manifest.json" ]; then
    SOURCE_VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$SOURCE_PACK_DIR/manifest.json" | grep -o '"[^"]*"$' | tr -d '"')
    echo "📦 Source core pack version: $SOURCE_VERSION"
else
    echo -e "${RED}❌ Error: manifest.json not found in source pack${NC}"
    exit 1
fi

# Get current version from destination if it exists
if [ -f "$DEST_PACK_DIR/manifest.json" ]; then
    DEST_VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$DEST_PACK_DIR/manifest.json" | grep -o '"[^"]*"$' | tr -d '"')
    echo "📱 Current app core pack version: $DEST_VERSION"
else
    echo "📱 No existing core pack found in app"
    DEST_VERSION="none"
fi

# Ask for confirmation
echo ""
echo "This will sync the core pack from IdeatorPromptPacks to Ideator app"
echo "Source: $SOURCE_PACK_DIR"
echo "Destination: $DEST_PACK_DIR"
echo ""
read -p "Do you want to continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Sync cancelled"
    exit 0
fi

# Backup existing pack if it exists
if [ -d "$DEST_PACK_DIR" ] && [ "$(ls -A $DEST_PACK_DIR)" ]; then
    BACKUP_DIR="$DEST_PACK_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📋 Creating backup at $BACKUP_DIR"
    cp -r "$DEST_PACK_DIR" "$BACKUP_DIR"
fi

# Perform the sync
echo "🔄 Syncing core pack files..."
cp -r "$SOURCE_PACK_DIR"/* "$DEST_PACK_DIR/"

# Count synced files
MANIFEST_COUNT=1
TSV_COUNT=$(ls -1 "$DEST_PACK_DIR"/*.tsv 2>/dev/null | wc -l)
TOTAL_FILES=$((MANIFEST_COUNT + TSV_COUNT))

echo -e "${GREEN}✅ Successfully synced $TOTAL_FILES files${NC}"
echo "   - 1 manifest.json"
echo "   - $TSV_COUNT TSV category files"

# Show git status
echo ""
echo "📊 Git status:"
cd "$SCRIPT_DIR"
git status --short Ideator/Resources/PromptPacks/Core/

echo ""
echo -e "${GREEN}✅ Core pack sync complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the changes with: git diff Ideator/Resources/PromptPacks/Core/"
echo "2. Test the app to ensure prompts load correctly"
echo "3. Commit when ready for release"
echo ""

# Version comparison hint
if [ "$DEST_VERSION" != "none" ] && [ "$SOURCE_VERSION" != "$DEST_VERSION" ]; then
    echo -e "${YELLOW}📌 Version changed from $DEST_VERSION to $SOURCE_VERSION${NC}"
    echo "   Remember to update app version if needed for this release"
fi
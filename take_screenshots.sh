#!/bin/bash
#
# take_screenshots.sh — Capture App Store Connect screenshots for all languages and devices.
#
# Usage:
#   ./take_screenshots.sh                       # all languages, all devices
#   ./take_screenshots.sh en                    # single language, all devices
#   ./take_screenshots.sh en de fr              # specific languages, all devices
#   ./take_screenshots.sh --iphone-only         # all languages, iPhone only
#   ./take_screenshots.sh --ipad-only           # all languages, iPad only
#   ./take_screenshots.sh --screen 01_home      # only capture one screen
#
# Requires: ScreenshotTests target in IdeatorUITests
#

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/Ideator.xcodeproj"
SCHEME="Ideator"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"
CONFIG_FILE_PROJECT="$PROJECT_DIR/.screenshot_config.json"
CONFIG_FILE_TMP="/tmp/ideator_screenshot_config.json"
DERIVED_DATA="$PROJECT_DIR/.build/DerivedData"
BUNDLE_ID="net.shadowpuppet.Ideator"

# Detect installed iOS simulator runtime version
IOS_VERSION=$(xcrun simctl list runtimes -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for r in sorted(data.get('runtimes', []), key=lambda x: x.get('version', ''), reverse=True):
    if r.get('isAvailable') and 'iOS' in r.get('name', ''):
        print(r['version']); sys.exit(0)
print('18.0')  # safe fallback
" 2>/dev/null)

# App Store Connect screenshot device specs
# Format: "Simulator Name|OS version|folder_name|test_method"
IPHONE_DEVICE="iPhone 16 Pro Max|${IOS_VERSION}|iphone_6.7|testCaptureIPhoneScreenshots"
IPAD_DEVICE="iPad Pro 13-inch (M4)|${IOS_VERSION}|ipad_13|testCaptureIPadScreenshots"

# Supported languages (add your app's localizations here)
ALL_LANGUAGES=("en")

# Currency code per locale
currency_for_locale() {
    case "$1" in
        en)    echo "USD" ;;
        de|fr|nl|es-ES|it) echo "EUR" ;;
        sv)    echo "SEK" ;;
        es-MX) echo "MXN" ;;
        pt-BR) echo "BRL" ;;
        ja)    echo "JPY" ;;
        zh-Hans) echo "CNY" ;;
        ko)    echo "KRW" ;;
        *)     echo "USD" ;;
    esac
}

# Parse arguments
LANGUAGES=()
DEVICES=()
SCREEN=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --iphone-only) DEVICES=("$IPHONE_DEVICE") ; shift ;;
        --ipad-only)   DEVICES=("$IPAD_DEVICE") ; shift ;;
        --screen)      SCREEN="$2" ; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [--iphone-only|--ipad-only] [--screen <name>] [lang1 lang2 ...]"
            echo ""
            echo "Languages: ${ALL_LANGUAGES[*]}"
            echo "Devices: iPhone 16 Pro Max (6.7\"), iPad Pro 13\" (M4)"
            exit 0
            ;;
        *)
            LANGUAGES+=("$1") ; shift ;;
    esac
done

# Defaults
[[ ${#LANGUAGES[@]} -eq 0 ]] && LANGUAGES=("${ALL_LANGUAGES[@]}")
[[ ${#DEVICES[@]} -eq 0 ]] && DEVICES=("$IPHONE_DEVICE" "$IPAD_DEVICE")

TOTAL_LANGS=${#LANGUAGES[@]}
TOTAL_DEVICES=${#DEVICES[@]}
TOTAL_RUNS=$((TOTAL_LANGS * TOTAL_DEVICES))
CURRENT_RUN=0
FAILED=()

echo "=========================================="
echo "  Ideator App Store Screenshot Capture"
echo "=========================================="
echo "  Languages: ${LANGUAGES[*]}"
echo "  Devices:   $TOTAL_DEVICES"
echo "  Total runs: $TOTAL_RUNS"
[[ -n "$SCREEN" ]] && echo "  Screen:    $SCREEN"
echo "  Output:    $SCREENSHOTS_DIR/{locale}/{device}/"
echo "=========================================="
echo ""

write_config() {
    local locale="$1"
    local device="$2"
    local output="$3"
    local currency
    currency=$(currency_for_locale "$locale")
    cat > "$CONFIG_FILE_PROJECT" <<JSONEOF
{
    "locale": "$locale",
    "device": "$device",
    "output_dir": "$output",
    "currency": "$currency",
    "target_screen": "$SCREEN"
}
JSONEOF
    cp "$CONFIG_FILE_PROJECT" "$CONFIG_FILE_TMP" 2>/dev/null || true
}

# Build test bundles (once per device)
for device_spec in "${DEVICES[@]}"; do
    IFS='|' read -r DEVICE_NAME DEVICE_OS DEVICE_FOLDER TEST_METHOD <<< "$device_spec"

    echo "🔨 Building test bundle for $DEVICE_NAME..."
    xcodebuild build-for-testing \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$DEVICE_NAME,OS=$DEVICE_OS" \
        -derivedDataPath "$DERIVED_DATA" \
        CODE_SIGNING_ALLOWED=NO \
        -quiet 2>&1 || {
            echo "❌ Build failed for $DEVICE_NAME"
            exit 1
        }
    echo "✅ Build complete for $DEVICE_NAME"
    echo ""
done

# Boot simulators and pre-grant notification permissions
for device_spec in "${DEVICES[@]}"; do
    IFS='|' read -r DEVICE_NAME _ _ _ <<< "$device_spec"
    echo "🚀 Booting $DEVICE_NAME simulator..."
    xcrun simctl boot "$DEVICE_NAME" 2>/dev/null || true
done
sleep 3
for device_spec in "${DEVICES[@]}"; do
    IFS='|' read -r DEVICE_NAME _ _ _ <<< "$device_spec"
    xcrun simctl privacy "$DEVICE_NAME" grant notifications "$BUNDLE_ID" 2>/dev/null || true
done

# Capture screenshots
for device_spec in "${DEVICES[@]}"; do
    IFS='|' read -r DEVICE_NAME DEVICE_OS DEVICE_FOLDER TEST_METHOD <<< "$device_spec"

    for LANG in "${LANGUAGES[@]}"; do
        CURRENT_RUN=$((CURRENT_RUN + 1))
        echo "📸 [$CURRENT_RUN/$TOTAL_RUNS] $LANG on $DEVICE_NAME..."

        write_config "$LANG" "$DEVICE_FOLDER" "$SCREENSHOTS_DIR"

        if xcodebuild test-without-building \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=$DEVICE_NAME,OS=$DEVICE_OS" \
            -derivedDataPath "$DERIVED_DATA" \
            -only-testing:"IdeatorUITests/ScreenshotTests/$TEST_METHOD" \
            CODE_SIGNING_ALLOWED=NO \
            -quiet 2>&1; then
            echo "   ✅ $LANG / $DEVICE_FOLDER complete"
        else
            echo "   ⚠️  $LANG / $DEVICE_FOLDER had failures (screenshots may still be saved)"
            FAILED+=("$LANG/$DEVICE_FOLDER")
        fi
    done
done

# Clean up config files
rm -f "$CONFIG_FILE_PROJECT" "$CONFIG_FILE_TMP"

# Summary
echo ""
echo "=========================================="
echo "  Screenshot Capture Complete"
echo "=========================================="

TOTAL_SCREENSHOTS=$(find "$SCREENSHOTS_DIR" -name "*.png" -newer "$PROJECT_DIR/take_screenshots.sh" 2>/dev/null | wc -l | tr -d ' ')
echo "  Screenshots captured: $TOTAL_SCREENSHOTS"
echo "  Output directory: $SCREENSHOTS_DIR/"
echo ""

for LANG in "${LANGUAGES[@]}"; do
    for device_spec in "${DEVICES[@]}"; do
        IFS='|' read -r _ _ DEVICE_FOLDER _ <<< "$device_spec"
        DIR="$SCREENSHOTS_DIR/$LANG/$DEVICE_FOLDER"
        if [[ -d "$DIR" ]]; then
            COUNT=$(ls "$DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
            echo "  $LANG/$DEVICE_FOLDER: $COUNT screenshots"
        fi
    done
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Runs with failures:"
    for f in "${FAILED[@]}"; do
        echo "  - $f"
    done
fi

echo ""
echo "Done! Upload screenshots to App Store Connect via Transporter or the web UI."

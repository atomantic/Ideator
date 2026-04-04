#!/bin/bash
set -euo pipefail

# Ideator (Idea Loom) - Local TestFlight Deploy
# Usage: ./deploy.sh [--skip-tests] [--ios] [--macos] [--all]
# Default (no platform flag): iOS only

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "❌ .env file not found. Copy .env.example to .env and fill in values."
    exit 1
fi

# Key path (already expanded via $HOME in .env)
KEY_PATH="$APPSTORE_API_PRIVATE_KEY_PATH"

if [ ! -f "$KEY_PATH" ]; then
    echo "❌ API key not found at: $KEY_PATH"
    exit 1
fi

# Ensure altool can find the key (it only checks specific directories)
mkdir -p ~/.private_keys
KEY_FILENAME="AuthKey_${APPSTORE_API_KEY_ID}.p8"
if [ ! -f ~/.private_keys/"$KEY_FILENAME" ]; then
    ln -sf "$KEY_PATH" ~/.private_keys/"$KEY_FILENAME"
    echo "🔑 Symlinked API key to ~/.private_keys/"
fi

PROJECT="Ideator.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/build"

# Parse flags
SKIP_TESTS=false
BUILD_IOS=false
BUILD_MACOS=false
for arg in "$@"; do
    case "$arg" in
        --skip-tests) SKIP_TESTS=true ;;
        --ios) BUILD_IOS=true ;;
        --macos) BUILD_MACOS=true ;;
        --all) BUILD_IOS=true; BUILD_MACOS=true ;;
    esac
done
# Default to iOS if no platform specified
if ! $BUILD_IOS && ! $BUILD_MACOS; then
    BUILD_IOS=true
fi

# Auto-increment build number in xcodeproj
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PROJECT/project.pbxproj" | awk '{print $3}' | tr -d ';')
NEW_BUILD=$((CURRENT_BUILD + 1))
echo "📦 Build number: $CURRENT_BUILD → $NEW_BUILD"
/usr/bin/sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PROJECT/project.pbxproj"

# Run tests (unless skipped)
if ! $SKIP_TESTS; then
    echo "🧪 Running tests..."
    DESTINATION=$(
        SIMINFO=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    parts = runtime.replace('com.apple.CoreSimulator.SimRuntime.iOS-', '').split('-')
    os_ver = '.'.join(parts)
    for d in devices:
        name = d.get('name', '')
        if d.get('isAvailable') and 'iPhone 16' in name and 'Plus' not in name and 'Pro' not in name and 'e' != name[-1:]:
            print(f'{name},{os_ver}')
            sys.exit(0)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    parts = runtime.replace('com.apple.CoreSimulator.SimRuntime.iOS-', '').split('-')
    os_ver = '.'.join(parts)
    for d in devices:
        if d.get('isAvailable') and 'iPhone' in d.get('name', ''):
            print(f\"{d['name']},{os_ver}\")
            sys.exit(0)
" 2>/dev/null)
        SIM_NAME="${SIMINFO%%,*}"
        SIM_OS="${SIMINFO##*,}"
        if [ -n "$SIM_NAME" ] && [ -n "$SIM_OS" ]; then
            echo "platform=iOS Simulator,name=$SIM_NAME,OS=$SIM_OS"
        else
            echo "platform=iOS Simulator,name=iPhone 16,OS=18.6"
        fi
    )
    xcodebuild test \
        -project "$PROJECT" \
        -scheme Ideator \
        -only-testing:IdeatorTests \
        -destination "$DESTINATION" \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        -quiet
    echo "✅ Tests passed"
fi

# Clean build directory
rm -rf "$BUILD_DIR"

# --- iOS Build & Upload ---
if $BUILD_IOS; then
    ARCHIVE_IOS="$BUILD_DIR/Ideator_iOS.xcarchive"
    EXPORT_IOS="$BUILD_DIR/export_ios"

    echo "📦 Archiving iOS..."
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme Ideator \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -archivePath "$ARCHIVE_IOS" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        -quiet
    echo "✅ iOS archive complete"

    cat > "$BUILD_DIR/exportOptions_ios.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
EOF

    echo "📤 Exporting iOS IPA..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_IOS" \
        -exportOptionsPlist "$BUILD_DIR/exportOptions_ios.plist" \
        -exportPath "$EXPORT_IOS" \
        -allowProvisioningUpdates \
        -authenticationKeyPath "$KEY_PATH" \
        -authenticationKeyID "$APPSTORE_API_KEY_ID" \
        -authenticationKeyIssuerID "$APPSTORE_ISSUER_ID" \
        -quiet
    echo "✅ iOS IPA exported"

    IPA_PATH="$EXPORT_IOS/Ideator.ipa"
    if [ ! -f "$IPA_PATH" ]; then
        echo "❌ iOS IPA not found at $IPA_PATH"
        ls -la "$EXPORT_IOS/"
        exit 1
    fi

    echo "🚀 Uploading iOS to TestFlight..."
    xcrun altool --upload-app \
        --file "$IPA_PATH" \
        --type ios \
        --apiKey "$APPSTORE_API_KEY_ID" \
        --apiIssuer "$APPSTORE_ISSUER_ID" \
        --transport DAV
    echo "✅ iOS upload complete!"

    if $BUILD_MACOS; then
        echo "⏳ Waiting 60s before macOS upload to avoid Apple CDN contention..."
        sleep 60
    fi
fi

# --- macOS Build & Upload ---
if $BUILD_MACOS; then
    ARCHIVE_MACOS="$BUILD_DIR/Ideator_macOS.xcarchive"
    EXPORT_MACOS="$BUILD_DIR/export_macos"

    echo "📦 Archiving macOS..."
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "Ideator macOS" \
        -configuration Release \
        -destination 'generic/platform=macOS' \
        -archivePath "$ARCHIVE_MACOS" \
        -allowProvisioningUpdates \
        -authenticationKeyPath "$KEY_PATH" \
        -authenticationKeyID "$APPSTORE_API_KEY_ID" \
        -authenticationKeyIssuerID "$APPSTORE_ISSUER_ID" \
        -quiet
    echo "✅ macOS archive complete"

    cat > "$BUILD_DIR/exportOptions_macos.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
EOF

    echo "📤 Exporting macOS pkg..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_MACOS" \
        -exportOptionsPlist "$BUILD_DIR/exportOptions_macos.plist" \
        -exportPath "$EXPORT_MACOS" \
        -allowProvisioningUpdates \
        -authenticationKeyPath "$KEY_PATH" \
        -authenticationKeyID "$APPSTORE_API_KEY_ID" \
        -authenticationKeyIssuerID "$APPSTORE_ISSUER_ID" \
        -quiet
    echo "✅ macOS pkg exported"

    PKG_PATH=$(find "$EXPORT_MACOS" -name "*.pkg" | head -1)
    if [ -z "$PKG_PATH" ]; then
        echo "❌ macOS package not found in $EXPORT_MACOS"
        ls -la "$EXPORT_MACOS/"
        exit 1
    fi

    echo "🚀 Uploading macOS to TestFlight..."
    if ! xcrun altool --upload-app \
        --file "$PKG_PATH" \
        --type macos \
        --apiKey "$APPSTORE_API_KEY_ID" \
        --apiIssuer "$APPSTORE_ISSUER_ID"; then
        echo "❌ macOS upload failed"
        exit 1
    fi
    echo "✅ macOS upload complete!"
fi

echo "✅ Build $NEW_BUILD submitted to TestFlight."

# Commit the build number bump
git add "$PROJECT/project.pbxproj"
git commit -m "build: bump to build $NEW_BUILD"
echo "📝 Committed build number bump"

# Clean up
rm -rf "$BUILD_DIR"
echo "🧹 Cleaned build artifacts"

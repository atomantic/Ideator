#!/bin/bash
set -euo pipefail

# Ideator (Idea Loom) - Local TestFlight Deploy
# Usage: ./deploy.sh [--skip-tests]

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
SCHEME="Ideator"
BUILD_DIR="$SCRIPT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$SCHEME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"

# Auto-increment build number in xcodeproj
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PROJECT/project.pbxproj" | awk '{print $3}' | tr -d ';')
NEW_BUILD=$((CURRENT_BUILD + 1))
echo "📦 Build number: $CURRENT_BUILD → $NEW_BUILD"
/usr/bin/sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PROJECT/project.pbxproj"

# Run tests (unless skipped)
if [ "${1:-}" != "--skip-tests" ]; then
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
        -scheme "$SCHEME" \
        -only-testing:IdeatorTests \
        -destination "$DESTINATION" \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        -quiet
    echo "✅ Tests passed"
fi

# Clean build directory
rm -rf "$BUILD_DIR"

# Archive
echo "📦 Archiving..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -quiet

echo "✅ Archive complete"

# Create exportOptions.plist
cat > "$BUILD_DIR/exportOptions.plist" <<EOF
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

# Export IPA
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$BUILD_DIR/exportOptions.plist" \
    -exportPath "$EXPORT_PATH" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID "$APPSTORE_API_KEY_ID" \
    -authenticationKeyIssuerID "$APPSTORE_ISSUER_ID" \
    -quiet

echo "✅ IPA exported"

# Upload to TestFlight
IPA_PATH="$EXPORT_PATH/$SCHEME.ipa"
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA not found at $IPA_PATH"
    ls -la "$EXPORT_PATH/"
    exit 1
fi

echo "🚀 Uploading to TestFlight..."
xcrun altool --upload-app \
    --file "$IPA_PATH" \
    --type ios \
    --apiKey "$APPSTORE_API_KEY_ID" \
    --apiIssuer "$APPSTORE_ISSUER_ID" \
    --transport DAV

UPLOAD_EXIT=$?
if [ $UPLOAD_EXIT -ne 0 ]; then
    echo "❌ Upload failed with exit code $UPLOAD_EXIT"
    exit $UPLOAD_EXIT
fi

echo "✅ Upload complete! Build $NEW_BUILD submitted to TestFlight."

# Commit the build number bump
git add "$PROJECT/project.pbxproj"
git commit -m "build: bump to build $NEW_BUILD"
echo "📝 Committed build number bump"

# Clean up
rm -rf "$BUILD_DIR"
echo "🧹 Cleaned build artifacts"

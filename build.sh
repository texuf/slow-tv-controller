#!/bin/bash
set -euo pipefail

DISPLAY_NAME="SlowTV Controller"
APP_NAME="SlowTVController"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"

# Find all Swift sources
SOURCES=$(find Sources -name "*.swift" -type f)

# Compile
swiftc \
    -target arm64-apple-macosx15.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework AppKit \
    -framework GameController \
    -framework CoreGraphics \
    -o "$MACOS_DIR/$APP_NAME" \
    $SOURCES

# Create Info.plist
cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.austinellis.slow-tv-controller</string>
    <key>CFBundleName</key>
    <string>$DISPLAY_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Code-sign so macOS TCC keeps accessibility permission across rebuilds
codesign --force --sign "Apple Development" --identifier com.austinellis.slow-tv-controller "$APP_BUNDLE"

echo "Built: $APP_BUNDLE"

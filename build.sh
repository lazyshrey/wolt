#!/bin/zsh
set -e

echo "⚡ Building Wolt for macOS (Apple Silicon)..."

APP_DIR="build/Wolt.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
CACHE_DIR="/tmp/swift-cache"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$CACHE_DIR"

# Process App Icon (from assets/ if user provided, or fallback to Resources/AppIcon.icns)
USER_ICON=$(find assets -maxdepth 1 -type f \( -iname "*icon*.png" -o -iname "*icon*.jpg" -o -iname "*logo*.png" -o -iname "*logo*.jpg" -o -name "AppIcon.*" \) 2>/dev/null | head -n 1)
USER_ICNS=$(find assets -maxdepth 1 -type f -name "*.icns" 2>/dev/null | head -n 1)

if [ -n "$USER_ICNS" ]; then
    echo "🎨 Found custom icon: $USER_ICNS"
    cp "$USER_ICNS" Resources/AppIcon.icns
elif [ -n "$USER_ICON" ]; then
    echo "🎨 Converting user asset $USER_ICON to macOS AppIcon.icns..."
    ICONSET_DIR="/tmp/WoltAppIcon.iconset"
    rm -rf "$ICONSET_DIR" && mkdir -p "$ICONSET_DIR"
    sips -z 16 16     "$USER_ICON" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null 2>&1
    sips -z 32 32     "$USER_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null 2>&1
    sips -z 32 32     "$USER_ICON" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null 2>&1
    sips -z 64 64     "$USER_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null 2>&1
    sips -z 128 128   "$USER_ICON" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null 2>&1
    sips -z 256 256   "$USER_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null 2>&1
    sips -z 256 256   "$USER_ICON" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null 2>&1
    sips -z 512 512   "$USER_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null 2>&1
    sips -z 512 512   "$USER_ICON" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null 2>&1
    sips -z 1024 1024 "$USER_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null 2>&1
    iconutil -c icns "$ICONSET_DIR" -o Resources/AppIcon.icns
    rm -rf "$ICONSET_DIR"
fi

if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

if [ -f "Resources/DefaultIcon.png" ]; then
    cp Resources/DefaultIcon.png "$RESOURCES_DIR/AppIcon.png"
fi

# Copy Info.plist
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"

SWIFT_SOURCES=(
    Sources/Wolt/Models/BatteryModel.swift
    Sources/Wolt/Models/AppSettings.swift
    Sources/Wolt/Services/PowerService.swift
    Sources/Wolt/Views/PowerFlowTabView.swift
    Sources/Wolt/Views/HealthTabView.swift
    Sources/Wolt/Views/SettingsTabView.swift
    Sources/Wolt/Views/PopoverContentView.swift
    Sources/Wolt/Views/MenuBarLabelView.swift
    Sources/Wolt/App.swift
)

swiftc \
    -disable-sandbox \
    -module-cache-path "$CACHE_DIR" \
    -parse-as-library \
    -O \
    -target arm64-apple-macosx14.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework IOKit \
    -framework Combine \
    -framework ServiceManagement \
    "${SWIFT_SOURCES[@]}" \
    -o "$MACOS_DIR/Wolt"

# Ad-hoc sign bundle for ServiceManagement & LaunchServices
codesign --force --deep -s - "$APP_DIR" >/dev/null 2>&1 || true

# Touch bundle to refresh Finder cache
touch "$APP_DIR"

# Install directly to /Applications if writable
if [ -d "/Applications" ] && [ -w "/Applications" ]; then
    echo "📲 Installing Wolt to /Applications/Wolt.app..."
    rm -rf /Applications/Wolt.app
    cp -R "$APP_DIR" /Applications/Wolt.app
    codesign --force --deep -s - /Applications/Wolt.app >/dev/null 2>&1 || true
    touch /Applications/Wolt.app
    
    # Register with LaunchServices
    LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    if [ -x "$LSREGISTER" ]; then
        "$LSREGISTER" -f /Applications/Wolt.app >/dev/null 2>&1 || true
        "$LSREGISTER" -f "$APP_DIR" >/dev/null 2>&1 || true
    fi
    echo "✨ Installed to /Applications/Wolt.app"
fi

# Package DMG if requested
if [ "$1" = "--dmg" ] || [ "$1" = "dmg" ]; then
    echo "💿 Packaging DMG installer..."
    mkdir -p dist
    DMG_TMP="/tmp/Wolt-DMG-Staging"
    rm -rf "$DMG_TMP" dist/Wolt-1.0.0-arm64.dmg
    mkdir -p "$DMG_TMP"
    cp -R "$APP_DIR" "$DMG_TMP/"
    ln -s /Applications "$DMG_TMP/Applications"
    hdiutil create -volname "Wolt" -srcfolder "$DMG_TMP" -ov -format UDZO "dist/Wolt-1.0.0-arm64.dmg" >/dev/null 2>&1
    rm -rf "$DMG_TMP"
    echo "✨ Production DMG created: dist/Wolt-1.0.0-arm64.dmg"
fi

echo "✅ Successfully built $APP_DIR"

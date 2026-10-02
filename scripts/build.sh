#!/bin/bash
# Builds build/Pomobar.app. Pass --install to copy it to /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")/.."

APP=build/Pomobar.app

if [[ ! -f Resources/AppIcon.icns ]]; then
    ICONSET=$(mktemp -d)/AppIcon.iconset
    swift scripts/make-icon.swift "$ICONSET"
    iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
fi

swift build -c release
BIN=$(swift build -c release --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Pomobar" "$APP/Contents/MacOS/Pomobar"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x Pomobar || true
    rm -rf /Applications/Pomobar.app
    cp -R "$APP" /Applications/
    open /Applications/Pomobar.app
    echo "Installed to /Applications"
fi

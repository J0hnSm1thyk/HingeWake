#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
APP="$ROOT/dist/HingeWake.app"
ZIP="$ROOT/dist/HingeWake.zip"
ICON_SOURCE="$ROOT/Resources/AppIcon.png"
ICONSET="$ROOT/.build/HingeWake-AppIcon.iconset"
ICNS="$ROOT/.build/HingeWake-AppIcon.icns"

cd "$ROOT"
swift build -c release

rm -rf "$ICONSET"
mkdir -p "$ICONSET"
/usr/bin/sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
/usr/bin/sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
/usr/bin/sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
/usr/bin/sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
/usr/bin/sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
/usr/bin/sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
/usr/bin/sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
/usr/bin/sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
/usr/bin/sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
/usr/bin/sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
/usr/bin/iconutil -c icns "$ICONSET" -o "$ICNS"
rm -rf "$ICONSET"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/HingeWake" "$APP/Contents/MacOS/HingeWake"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
chmod 755 "$APP/Contents/MacOS/HingeWake"
/usr/bin/codesign --force --sign - --timestamp=none --options runtime "$APP"
/usr/bin/codesign --verify --deep --strict "$APP"
/usr/bin/plutil -lint "$APP/Contents/Info.plist"
rm -f "$ZIP"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
/usr/bin/unzip -t "$ZIP" >/dev/null
print "Build complete: $APP"
print "ZIP created and verified: $ZIP"

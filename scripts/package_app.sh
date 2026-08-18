#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

swift build -c release --arch arm64
BIN_DIR=$(swift build -c release --arch arm64 --show-bin-path)
if [ ! -x "$BIN_DIR/Shotser" ]; then
	printf 'Build completed without an executable at %s/Shotser\n' "$BIN_DIR" >&2
	exit 1
fi
APP_DIR="$ROOT_DIR/dist/Shotser.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/Shotser" "$APP_DIR/Contents/MacOS/Shotser"
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"
chmod +x "$APP_DIR/Contents/MacOS/Shotser"

/usr/bin/codesign --force --deep --sign - "$APP_DIR"

ARCHIVE="$ROOT_DIR/dist/Shotser-macOS-arm64.zip"
rm -f "$ARCHIVE"
/usr/bin/ditto --norsrc --noextattr --noqtn -c -k --keepParent "$APP_DIR" "$ARCHIVE"
printf 'Created %s\n' "$ARCHIVE"

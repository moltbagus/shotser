#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$MODE" in
  run|--verify|verify|--logs|logs) ;;
  *)
    echo "usage: $0 [run|--verify|--logs]" >&2
    exit 2
    ;;
esac

case "$(uname -m)" in
  arm64) TAURI_TARGET="aarch64-apple-darwin" ;;
  x86_64) TAURI_TARGET="x86_64-apple-darwin" ;;
  *) echo "Unsupported macOS architecture: $(uname -m)" >&2; exit 1 ;;
esac

APP_BUNDLE="$ROOT_DIR/tauri-app/src-tauri/target/$TAURI_TARGET/release/bundle/macos/ShotEye.app"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/shoteye"
INSTALLED_APP_BUNDLE="/Applications/ShotEye.app"

"$ROOT_DIR/scripts/package_app.sh"
"$ROOT_DIR/scripts/install_app.sh" "$APP_BUNDLE"

case "$MODE" in
  run)
    /usr/bin/open -a "$INSTALLED_APP_BUNDLE"
    ;;
  --verify|verify)
    "$ROOT_DIR/scripts/verify_app.sh" --launch
    ;;
  --logs|logs)
    /usr/bin/open -a "$INSTALLED_APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate 'process == "shoteye"'
    ;;
esac

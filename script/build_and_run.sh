#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Shotser"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
"$ROOT_DIR/scripts/package_app.sh"

case "$MODE" in
  run)
    /usr/bin/open -n "$APP_BUNDLE"
    ;;
  --verify|verify)
    /usr/bin/open -n "$APP_BUNDLE"
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --logs|logs)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  *)
    echo "usage: $0 [run|--verify|--logs]" >&2
    exit 2
    ;;
esac

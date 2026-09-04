#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_RUNNER="$ROOT_DIR/script/build_and_run.sh"
APP_VERIFIER="$ROOT_DIR/scripts/verify_app.sh"
UI_SMOKE="$ROOT_DIR/scripts/verify_ui_smoke.sh"
PACKAGE_SCRIPT="$ROOT_DIR/scripts/package_app.sh"

for script_path in "$BUILD_RUNNER" "$APP_VERIFIER" "$UI_SMOKE" "$PACKAGE_SCRIPT"; do
  test -f "$script_path"
  test -x "$script_path"
  if /usr/bin/grep -Fq '/usr/bin/open -n' "$script_path"; then
    printf 'Unsupported multi-instance launch flag found in %s\n' "$script_path" >&2
    exit 1
  fi
done

/usr/bin/grep -Fq '/usr/bin/open -a "$INSTALLED_APP_BUNDLE"' "$BUILD_RUNNER"
/usr/bin/grep -Fq '/usr/bin/open -a "$APP_PATH"' "$APP_VERIFIER"
/usr/bin/grep -Fq '/usr/bin/open -a "$APP_PATH"' "$UI_SMOKE"
/usr/bin/grep -Fq 'target/$TAURI_TARGET/release/bundle/macos/ShotEye.app' "$BUILD_RUNNER"
/usr/bin/grep -Fq 'target/$TAURI_TARGET/release/bundle/macos/ShotEye.app' "$APP_VERIFIER"
/usr/bin/grep -Fq 'STALE_BUILD_BUNDLE=' "$PACKAGE_SCRIPT"
/usr/bin/grep -Fq 'Archived stale unqualified ShotEye bundle' "$PACKAGE_SCRIPT"
/usr/bin/grep -Fq 'A stale unqualified ShotEye bundle is currently running' "$PACKAGE_SCRIPT"
/usr/bin/grep -Fq 'STALE_BUILD_APP_PATH=' "$APP_VERIFIER"
/usr/bin/grep -Fq 'Unsupported unqualified ShotEye bundle found under the build tree' "$APP_VERIFIER"
/usr/bin/grep -Fq 'stop_exact_process "/Applications/ShotEye.app/Contents/MacOS/shoteye"' "$APP_VERIFIER"
/usr/bin/grep -Fq 'PAYLOAD_LAUNCHED=1' "$APP_VERIFIER"
/usr/bin/grep -Fq 'canonical_process_path()' "$APP_VERIFIER"
/usr/bin/grep -Fq 'process_count=$(running_process_ids "$APP_EXECUTABLE"' "$APP_VERIFIER"

printf '%s\n' 'Canonical launch contract passed: supported scripts focus one installed ShotEye.app, never use open -n, and archive stale unqualified bundles safely.'

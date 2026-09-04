#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TRACE_ROOT=$(mktemp -d -t shoteye-release-order)
TRACE_PATH="$TRACE_ROOT/trace"

cleanup() {
	rm -rf "$TRACE_ROOT"
}
trap cleanup EXIT HUP INT TERM

APPLE_ID="release-test@example.com"
APPLE_TEAM_ID="TEAMTEST"
APPLE_PASSWORD="not-a-real-password"
export APPLE_ID APPLE_TEAM_ID APPLE_PASSWORD

# Replace only the notarization CLI for this credential-free contract test.
# The shared helper must still issue the real command shapes in the real
# package flow; this function records their order without contacting Apple.
xcrun() {
	printf '%s\n' "$*" >> "$TRACE_PATH"
}

if [ ! -f "$ROOT_DIR/scripts/release_notarization.sh" ]; then
	printf '%s\n' 'Release notarization helper is missing.' >&2
	exit 1
fi

. "$ROOT_DIR/scripts/release_notarization.sh"

shoteye_notarize_and_staple_app "/tmp/ShotEye.app" "/tmp/ShotEye.app.zip"
shoteye_notarize_and_staple_dmg "/tmp/ShotEye.dmg"

package_script="$ROOT_DIR/scripts/package_app.sh"
app_notary_line=$(awk 'index($0, "shoteye_notarize_and_staple_app \"$APP_PATH\"") { print NR; exit }' "$package_script")
dmg_create_line=$(awk 'index($0, "hdiutil create") { print NR; exit }' "$package_script")
dmg_notary_line=$(awk 'index($0, "shoteye_notarize_and_staple_dmg \"$DMG_PATH\"") { print NR; exit }' "$package_script")
canonical_copy_line=$(awk 'index($0, "CANONICAL_DMG_STAGE=$(mktemp") { print NR; exit }' "$package_script")
if [ -z "$app_notary_line" ] || [ -z "$dmg_create_line" ] || [ -z "$dmg_notary_line" ] || [ -z "$canonical_copy_line" ] \
	|| [ "$app_notary_line" -ge "$dmg_create_line" ] \
	|| [ "$dmg_create_line" -ge "$dmg_notary_line" ] \
	|| [ "$dmg_notary_line" -ge "$canonical_copy_line" ]; then
	printf '%s\n' 'Package script release ordering is invalid.' >&2
	exit 1
fi

actual=$(sed -n '1,10p' "$TRACE_PATH")
expected='notarytool submit /tmp/ShotEye.app.zip --apple-id release-test@example.com --team-id TEAMTEST --password not-a-real-password --wait
stapler staple /tmp/ShotEye.app
stapler validate /tmp/ShotEye.app
notarytool submit /tmp/ShotEye.dmg --apple-id release-test@example.com --team-id TEAMTEST --password not-a-real-password --wait
stapler staple /tmp/ShotEye.dmg
stapler validate /tmp/ShotEye.dmg'

if [ "$actual" != "$expected" ]; then
	printf 'Release notarization order mismatch.\nExpected:\n%s\nActual:\n%s\n' "$expected" "$actual" >&2
	exit 1
fi

printf '%s\n' 'ShotEye release notarization ordering contract passed.'

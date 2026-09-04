#!/bin/sh

# Shared release-only notarization boundaries. This file is sourced by the
# package script so the ordering can be verified without Apple credentials.

shoteye_notary_submit() {
	artifact_path=$1
	if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && [ -n "${APPLE_PASSWORD:-}" ]; then
		xcrun notarytool submit "$artifact_path" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_PASSWORD" --wait
	else
		xcrun notarytool submit "$artifact_path" --key "$APPLE_API_KEY_PATH" --key-id "$APPLE_API_KEY" --issuer "$APPLE_API_ISSUER" --wait
	fi
}

shoteye_notarize_and_staple_app() {
	app_path=$1
	archive_path=$2
	shoteye_notary_submit "$archive_path"
	xcrun stapler staple "$app_path"
	if ! xcrun stapler validate "$app_path"; then
		printf '%s\n' 'The release app has no valid stapled notarization ticket.' >&2
		return 1
	fi
}

shoteye_notarize_and_staple_dmg() {
	dmg_path=$1
	shoteye_notary_submit "$dmg_path"
	xcrun stapler staple "$dmg_path"
	if ! xcrun stapler validate "$dmg_path"; then
		printf '%s\n' 'The release DMG has no valid stapled notarization ticket.' >&2
		return 1
	fi
}

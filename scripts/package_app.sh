#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TAURI_DIR="$ROOT_DIR/tauri-app"
PACKAGE_MODE="local"

. "$ROOT_DIR/scripts/release_notarization.sh"

if [ -d "$ROOT_DIR/dist" ]; then
	ROOT_APP_BUNDLE=$(find "$ROOT_DIR/dist" -maxdepth 1 -type d -name '*.app' -print -quit)
	if [ -n "$ROOT_APP_BUNDLE" ]; then
		printf 'Unsupported app bundle found under the repository build root: %s. Archive it outside dist/ before packaging ShotEye.\n' "$ROOT_APP_BUNDLE" >&2
		exit 1
	fi
fi

case "${1:-}" in
	"") ;;
	--local) ;;
	--release) PACKAGE_MODE="release" ;;
	*)
		printf 'Usage: %s [--local|--release]\n' "$0" >&2
		exit 2
		;;
esac

case "$(uname -m)" in
	arm64) TAURI_TARGET="aarch64-apple-darwin"; EXPECTED_MACHO="arm64" ;;
	x86_64) TAURI_TARGET="x86_64-apple-darwin"; EXPECTED_MACHO="x86_64" ;;
	*)
		printf 'Unsupported macOS architecture: %s\n' "$(uname -m)" >&2
		exit 1
		;;
esac

if [ ! -x "$TAURI_DIR/node_modules/.bin/tauri" ]; then
	printf 'ShotEye dependencies are missing. Run npm ci in %s first.\n' "$TAURI_DIR" >&2
	exit 1
fi

TAURI_CONFIG_OVERRIDE=""
LOCAL_SIGNING_IDENTITY=""
BUNDLE_SIGNING_IDENTITY=""
CODESIGN_TIMESTAMP_ARGS=""
probe_local_signing_identity() {
	PROBE_ROOT=$(mktemp -d -t shoteye-signing-probe)
	PROBE_BINARY="$PROBE_ROOT/true"
	PROBE_OUTPUT="$PROBE_ROOT/output"
	cp /usr/bin/true "$PROBE_BINARY"
	codesign --force --sign "ShotEye Local Development" --timestamp=none "$PROBE_BINARY" >"$PROBE_OUTPUT" 2>&1 &
	PROBE_PID=$!
	PROBE_FINISHED=0
	for _ in $(seq 1 20); do
		if ! kill -0 "$PROBE_PID" 2>/dev/null; then
			PROBE_FINISHED=1
			break
		fi
		sleep 0.25
	done
	if [ "$PROBE_FINISHED" -eq 0 ]; then
		kill -TERM "$PROBE_PID" 2>/dev/null || true
		sleep 0.1
		kill -KILL "$PROBE_PID" 2>/dev/null || true
		wait "$PROBE_PID" 2>/dev/null || true
		rm -rf "$PROBE_ROOT"
		printf 'Local signing identity was found but codesign could not access its private key non-interactively; falling back to ad-hoc signing. Unlock the keychain or grant codesign access to use it.\n' >&2
		return 1
	fi
	if ! wait "$PROBE_PID"; then
		rm -rf "$PROBE_ROOT"
		printf 'Local signing identity was found but codesign rejected it; falling back to ad-hoc signing.\n' >&2
		return 1
	fi
	rm -rf "$PROBE_ROOT"
	return 0
}
if [ "$PACKAGE_MODE" = "release" ]; then
	if [ -z "${SHOT_EYE_SIGNING_IDENTITY:-}" ]; then
		printf 'Release packaging requires SHOT_EYE_SIGNING_IDENTITY set to a Developer ID Application identity.\n' >&2
		exit 1
	fi
	case "$SHOT_EYE_SIGNING_IDENTITY" in
		'Developer ID Application: '*) ;;
		*)
			printf 'SHOT_EYE_SIGNING_IDENTITY must be the complete Developer ID Application identity string.\n' >&2
			exit 1
			;;
	esac
	if ! security find-identity -v -p codesigning 2>/dev/null | grep -Fq "\"$SHOT_EYE_SIGNING_IDENTITY\""; then
		printf 'No matching Developer ID Application identity was found for the requested release signer.\n' >&2
		exit 1
	fi
	if [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_TEAM_ID:-}" ] || [ -z "${APPLE_PASSWORD:-}" ]; then
		if [ -z "${APPLE_API_KEY:-}" ] || [ -z "${APPLE_API_ISSUER:-}" ] || [ -z "${APPLE_API_KEY_PATH:-}" ]; then
			printf 'Release packaging requires Apple notarization credentials: APPLE_ID/APPLE_TEAM_ID/APPLE_PASSWORD or APPLE_API_KEY/APPLE_API_ISSUER/APPLE_API_KEY_PATH.\n' >&2
			exit 1
		fi
	fi
	case "$SHOT_EYE_SIGNING_IDENTITY" in
		*'"'*|*'\\'*)
			printf 'The release signing identity contains unsupported JSON quoting characters.\n' >&2
			exit 1
			;;
	esac
	BUNDLE_SIGNING_IDENTITY="$SHOT_EYE_SIGNING_IDENTITY"
	TAURI_CONFIG_OVERRIDE=$(printf '{"bundle":{"macOS":{"signingIdentity":"%s"}}}' "$SHOT_EYE_SIGNING_IDENTITY")
	elif command -v security >/dev/null 2>&1 && security find-identity -v -p codesigning 2>/dev/null | grep -Fq '"ShotEye Local Development"' && probe_local_signing_identity; then
		# Keep local TCC identity continuity when the opt-in development certificate
		# exists. On another Mac without it, preserve the existing ad-hoc fallback.
		LOCAL_SIGNING_IDENTITY="ShotEye Local Development"
		BUNDLE_SIGNING_IDENTITY="$LOCAL_SIGNING_IDENTITY"
		CODESIGN_TIMESTAMP_ARGS="--timestamp=none"
		TAURI_CONFIG_OVERRIDE=$(printf '{"bundle":{"macOS":{"signingIdentity":"%s"}}}' "$LOCAL_SIGNING_IDENTITY")
	printf 'Using local signing identity: %s\n' "$LOCAL_SIGNING_IDENTITY"
fi

# A previous unqualified Tauri build can remain launchable beside the
# architecture-specific bundle. Do not let a direct package invocation leave
# that competing app in place: archive it recoverably, and fail closed if it
# is currently running so we never move a live user process behind their back.
STALE_BUILD_BUNDLE="$TAURI_DIR/src-tauri/target/release/bundle/macos/ShotEye.app"
if [ -d "$STALE_BUILD_BUNDLE" ]; then
	STALE_BUILD_EXECUTABLE="$STALE_BUILD_BUNDLE/Contents/MacOS/shoteye"
	if /bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$STALE_BUILD_EXECUTABLE" '$2 == expected {found=1} END {exit(found ? 0 : 1)}'; then
		printf 'A stale unqualified ShotEye bundle is currently running: %s. Stop it before packaging the architecture-specific app.\n' "$STALE_BUILD_BUNDLE" >&2
		exit 1
	fi
	STALE_ARCHIVE_DIR=$(mktemp -d -t shoteye-retired-build)
	mv "$STALE_BUILD_BUNDLE" "$STALE_ARCHIVE_DIR/ShotEye.app"
	printf 'Archived stale unqualified ShotEye bundle at %s\n' "$STALE_ARCHIVE_DIR/ShotEye.app"
fi

cd "$TAURI_DIR"
if [ -n "$TAURI_CONFIG_OVERRIDE" ]; then
	npm run tauri -- build --target "$TAURI_TARGET" --bundles app --config "$TAURI_CONFIG_OVERRIDE"
else
	npm run tauri -- build --target "$TAURI_TARGET" --bundles app
fi

BUNDLE_ROOT="$TAURI_DIR/src-tauri/target/$TAURI_TARGET/release/bundle"
APP_PATH="$BUNDLE_ROOT/macos/ShotEye.app"
if [ ! -d "$APP_PATH" ]; then
	printf 'ShotEye package was not created at %s\n' "$APP_PATH" >&2
	exit 1
fi

for binary in "$APP_PATH/Contents/MacOS/shoteye" "$APP_PATH/Contents/Resources/native/ShotEyeSelector"; do
	if [ ! -x "$binary" ]; then
		printf 'ShotEye package contains a missing or non-executable binary: %s\n' "$binary" >&2
		exit 1
	fi
	if ! /usr/bin/file "$binary" | /usr/bin/grep -q "Mach-O.*$EXPECTED_MACHO"; then
		printf 'ShotEye package contains an unexpected architecture: %s\n' "$binary" >&2
		/usr/bin/file "$binary" >&2
		exit 1
	fi
done

HELPER_PATH="$APP_PATH/Contents/Resources/native/ShotEyeSelector"
if [ -n "$BUNDLE_SIGNING_IDENTITY" ]; then
	# Tauri signs the app bundle but treats this selector as a resource. Sign the
	# helper first, then re-sign the containing bundle so both executable layers
	# share the same stable identity and TCC sees one release lineage.
	codesign --force --sign "$BUNDLE_SIGNING_IDENTITY" --options runtime $CODESIGN_TIMESTAMP_ARGS "$HELPER_PATH"
	codesign --force --sign "$BUNDLE_SIGNING_IDENTITY" --options runtime $CODESIGN_TIMESTAMP_ARGS "$APP_PATH"
fi

case "$TAURI_TARGET" in
	aarch64-apple-darwin) DMG_ARCH="aarch64" ;;
	x86_64-apple-darwin) DMG_ARCH="x86_64" ;;
	*)
		printf 'Unsupported DMG architecture target: %s\n' "$TAURI_TARGET" >&2
		exit 1
		;;
esac

if [ "$PACKAGE_MODE" = "release" ]; then
	if ! codesign --verify --deep --strict "$APP_PATH"; then
		printf 'Developer ID package failed strict code-signature validation.\n' >&2
		exit 1
	fi
	APP_SIGNATURE_DETAILS=$(codesign --display --verbose=4 "$APP_PATH" 2>&1)
	if ! printf '%s\n' "$APP_SIGNATURE_DETAILS" | grep -Fq 'Authority=Developer ID Application:'; then
		printf 'Package is not signed by a Developer ID Application identity.\n' >&2
		exit 1
	fi
	APP_TEAM_IDENTIFIER=$(printf '%s\n' "$APP_SIGNATURE_DETAILS" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
	if [ -z "$APP_TEAM_IDENTIFIER" ] || [ "$APP_TEAM_IDENTIFIER" = "not set" ]; then
		printf 'Package does not contain a Developer ID TeamIdentifier.\n' >&2
		exit 1
	fi
	if ! codesign --verify --strict "$HELPER_PATH"; then
		printf 'Bundled ShotEyeSelector failed strict code-signature validation.\n' >&2
		exit 1
	fi
	HELPER_SIGNATURE_DETAILS=$(codesign --display --verbose=4 "$HELPER_PATH" 2>&1)
	if ! printf '%s\n' "$HELPER_SIGNATURE_DETAILS" | grep -Fq 'Authority=Developer ID Application:'; then
		printf 'Bundled ShotEyeSelector is not signed by a Developer ID Application identity.\n' >&2
		exit 1
	fi
	HELPER_TEAM_IDENTIFIER=$(printf '%s\n' "$HELPER_SIGNATURE_DETAILS" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
	if [ "$HELPER_TEAM_IDENTIFIER" != "$APP_TEAM_IDENTIFIER" ]; then
		printf 'Bundled ShotEyeSelector TeamIdentifier does not match the app TeamIdentifier.\n' >&2
		exit 1
	fi
	APP_ARCHIVE_PATH="$BUNDLE_ROOT/ShotEye_0.1.0_${DMG_ARCH}.zip"
	rm -f "$APP_ARCHIVE_PATH"
	ditto -c -k --keepParent "$APP_PATH" "$APP_ARCHIVE_PATH"
	shoteye_notarize_and_staple_app "$APP_PATH" "$APP_ARCHIVE_PATH"
	if ! spctl --assess --type execute "$APP_PATH"; then
		printf 'Gatekeeper rejected the notarized release app.\n' >&2
		exit 1
	fi
fi

DMG_DIR="$BUNDLE_ROOT/dmg"
mkdir -p "$DMG_DIR"
DMG_PATH="$DMG_DIR/ShotEye_0.1.0_${DMG_ARCH}.dmg"
RELEASE_ARTIFACT_DIR="$ROOT_DIR/artifacts/releases"
CANONICAL_DMG_PATH="$RELEASE_ARTIFACT_DIR/ShotEye_0.1.0_${DMG_ARCH}.dmg"
mkdir -p "$RELEASE_ARTIFACT_DIR"
DMG_STAGE=$(mktemp -d -t shoteye-dmg-stage)
CANONICAL_DMG_STAGE=""
cleanup_dmg_stage() {
	rm -rf "$DMG_STAGE"
	if [ -n "${CANONICAL_DMG_STAGE:-}" ]; then
		rm -f "$CANONICAL_DMG_STAGE"
	fi
}
trap cleanup_dmg_stage EXIT HUP INT TERM
cp -R "$APP_PATH" "$DMG_STAGE/ShotEye.app"
ln -s /Applications "$DMG_STAGE/Applications"
hdiutil create -quiet -ov -format UDZO -volname "ShotEye" -srcfolder "$DMG_STAGE" "$DMG_PATH"

if [ "$PACKAGE_MODE" = "release" ]; then
	# The DMG must be built from the already notarized/stapled app. Staple the
	# distribution image before refreshing the canonical download artifact.
	shoteye_notarize_and_staple_dmg "$DMG_PATH"
fi

CANONICAL_DMG_STAGE=$(mktemp "$RELEASE_ARTIFACT_DIR/.ShotEye-${DMG_ARCH}.XXXXXX")
cp "$DMG_PATH" "$CANONICAL_DMG_STAGE"
mv -f "$CANONICAL_DMG_STAGE" "$CANONICAL_DMG_PATH"
CANONICAL_DMG_STAGE=""
if ! cmp -s "$DMG_PATH" "$CANONICAL_DMG_PATH"; then
	printf 'Canonical ShotEye DMG is not byte-identical to the package output: %s\n' "$CANONICAL_DMG_PATH" >&2
	exit 1
fi
cleanup_dmg_stage
trap - EXIT HUP INT TERM

printf 'Created %s\n' "$APP_PATH"
printf 'Created %s\n' "$DMG_PATH"
printf 'Refreshed canonical download %s\n' "$CANONICAL_DMG_PATH"

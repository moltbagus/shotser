#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_PATH=/Applications/ShotEye.app
STALE_BUILD_APP_PATH="$ROOT_DIR/tauri-app/src-tauri/target/release/bundle/macos/ShotEye.app"
ARTIFACT_PATH=""
REQUESTED_DMG_PATH=""
REPORT_PATH=""
LAUNCH=0
REQUIRE_RELEASE=0

if [ -d "$ROOT_DIR/dist" ]; then
  ROOT_APP_BUNDLE=$(find "$ROOT_DIR/dist" -maxdepth 1 -type d -name '*.app' -print -quit)
  if [ -n "$ROOT_APP_BUNDLE" ]; then
    printf 'Unsupported app bundle found under the repository build root: %s. Archive it outside dist/ before verification.\n' "$ROOT_APP_BUNDLE" >&2
    exit 1
  fi
fi

if [ -d "$STALE_BUILD_APP_PATH" ]; then
  printf 'Unsupported unqualified ShotEye bundle found under the build tree: %s. Run package_app.sh to archive it before verification.\n' "$STALE_BUILD_APP_PATH" >&2
  exit 1
fi

if [ "${SHOT_EYE_DMG_PAYLOAD:-0}" -eq 1 ]; then
  if [ -z "${SHOT_EYE_DMG_PAYLOAD_PATH:-}" ]; then
    printf '%s\n' 'Internal DMG verification is missing its mounted app path.' >&2
    exit 2
  fi
  APP_PATH=$SHOT_EYE_DMG_PAYLOAD_PATH
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --launch)
      LAUNCH=1
      ;;
    --artifact)
      shift
      if [ "$#" -eq 0 ]; then
        printf '%s\n' '--artifact requires a PNG path.' >&2
        exit 2
      fi
      ARTIFACT_PATH=$1
      ;;
    --dmg)
      shift
      if [ "$#" -eq 0 ]; then
        printf '%s\n' '--dmg requires a DMG path.' >&2
        exit 2
      fi
      REQUESTED_DMG_PATH=$1
      ;;
    --report)
      shift
      if [ "$#" -eq 0 ]; then
        printf '%s\n' '--report requires an output path.' >&2
        exit 2
      fi
      REPORT_PATH=$1
      ;;
    --release|--require-developer-id)
      REQUIRE_RELEASE=1
      ;;
    *)
      printf 'Usage: %s [--launch] [--artifact PNG] [--dmg DMG] [--report PATH] [--release]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

case "$(uname -m)" in
  arm64) EXPECTED_MACHO="arm64"; TAURI_TARGET="aarch64-apple-darwin" ;;
  x86_64) EXPECTED_MACHO="x86_64"; TAURI_TARGET="x86_64-apple-darwin" ;;
  *)
    printf 'Unsupported macOS architecture: %s\n' "$(uname -m)" >&2
    exit 1
    ;;
esac

BUILT_APP="$ROOT_DIR/tauri-app/src-tauri/target/$TAURI_TARGET/release/bundle/macos/ShotEye.app"
case "$TAURI_TARGET" in
  aarch64-apple-darwin) DMG_ARCH="aarch64" ;;
  x86_64-apple-darwin) DMG_ARCH="x86_64" ;;
  *)
    printf 'Unsupported DMG architecture target: %s\n' "$TAURI_TARGET" >&2
    exit 1
    ;;
esac
BUILT_DMG_PATH="$ROOT_DIR/tauri-app/src-tauri/target/$TAURI_TARGET/release/bundle/dmg/ShotEye_0.1.0_${DMG_ARCH}.dmg"
CANONICAL_DMG_PATH="$ROOT_DIR/artifacts/releases/ShotEye_0.1.0_${DMG_ARCH}.dmg"

helper_capture_test_dir=""
helper_capture_test_output=""
helper_capture_test_sha=""
helper_capture_test_dimensions=""

canonical_process_path() {
  process_path=$1
  process_directory=$(CDPATH= cd -- "$(/usr/bin/dirname "$process_path")" 2>/dev/null && /bin/pwd -P) || {
    printf '%s\n' "$process_path"
    return 0
  }
  printf '%s/%s\n' "$process_directory" "$(/usr/bin/basename "$process_path")"
}

running_process_ids() {
  process_path=$(canonical_process_path "$1")
  /bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$process_path" '$2 == expected {print $1}'
}

stop_exact_process() {
  process_path=$1
  process_ids=$(running_process_ids "$process_path")
  [ -z "$process_ids" ] && return 0
  for process_id in $process_ids; do
    /bin/kill -TERM "$process_id" 2>/dev/null || true
  done
  attempts=0
  while [ "$attempts" -lt 40 ]; do
    process_ids=$(running_process_ids "$process_path")
    [ -z "$process_ids" ] && return 0
    /bin/sleep 0.05
    attempts=$((attempts + 1))
  done
  for process_id in $process_ids; do
    /bin/kill -KILL "$process_id" 2>/dev/null || true
  done
  process_ids=$(running_process_ids "$process_path")
  if [ -n "$process_ids" ]; then
    printf 'Could not stop the exact ShotEye verification process: %s\n' "$process_path" >&2
    return 1
  fi
}

cleanup_helper_capture_self_test() {
  if [ -n "$helper_capture_test_output" ]; then
    rm -f "$helper_capture_test_output"
  fi
  if [ -n "$helper_capture_test_dir" ]; then
    rmdir "$helper_capture_test_dir" >/dev/null 2>&1 || true
  fi
  helper_capture_test_dir=""
  helper_capture_test_output=""
}

run_helper_capture_self_test() {
  helper_path=$1
  helper_capture_test_dir=$(mktemp -d -t shoteye-capture-output)
  helper_capture_test_output="$helper_capture_test_dir/ShotEye-self-test.png"
  "$helper_path" --self-test-capture-output "$helper_capture_test_output"
  test -s "$helper_capture_test_output"
  /usr/bin/file "$helper_capture_test_output" | /usr/bin/grep -q 'PNG image data'
  test "$(xxd -l 8 -p "$helper_capture_test_output")" = 89504e470d0a1a0a
  helper_capture_test_dimensions=$(sips -g pixelWidth -g pixelHeight "$helper_capture_test_output" 2>/dev/null | awk '/pixelWidth/{width=$2} /pixelHeight/{height=$2} END{printf "%sx%s", width, height}')
  test "$helper_capture_test_dimensions" = "8x4"
  helper_capture_test_sha=$(shasum -a 256 "$helper_capture_test_output" | awk '{print $1}')
}

write_report() {
  report_path=$1
  report_app=$2
  report_dmg=$3
  report_dir=$(dirname "$report_path")
  test -d "$report_dir"
  report_bundle_executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$report_app/Contents/Info.plist")
  report_bundle_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$report_app/Contents/Info.plist")
  report_app_signature_details=$(codesign --display --verbose=4 "$report_app" 2>&1 || true)
  report_helper_signature_details=$(codesign --display --verbose=4 "$report_app/Contents/Resources/native/ShotEyeSelector" 2>&1 || true)
  report_app_team_identifier=$(printf '%s\n' "$report_app_signature_details" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
  report_helper_team_identifier=$(printf '%s\n' "$report_helper_signature_details" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
  {
    printf '%s\n' 'ShotEye package verification report'
    printf 'Generated (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    if [ "$REQUIRE_RELEASE" -eq 1 ]; then
      printf '%s\n' 'Verification mode: release-ready (Developer ID and notarization required)'
    else
      printf '%s\n' 'Verification mode: local-only (strict structure; Developer ID and notarization not required)'
    fi
    printf 'App path: %s\n' "$report_app"
    printf 'Bundle: %s (%s)\n' "$report_bundle_executable" "$report_bundle_identifier"
    printf 'App signature authority: %s\n' "$(printf '%s\n' "$report_app_signature_details" | awk -F= '/^Authority=/{print $2; exit}')"
    printf 'App TeamIdentifier: %s\n' "$report_app_team_identifier"
    printf 'Helper signature authority: %s\n' "$(printf '%s\n' "$report_helper_signature_details" | awk -F= '/^Authority=/{print $2; exit}')"
    printf 'Helper TeamIdentifier: %s\n' "$report_helper_team_identifier"
    printf 'App executable SHA-256: %s\n' "$(shasum -a 256 "$report_app/Contents/MacOS/shoteye" | awk '{print $1}')"
    printf 'Helper SHA-256: %s\n' "$(shasum -a 256 "$report_app/Contents/Resources/native/ShotEyeSelector" | awk '{print $1}')"
    report_permission_exit=0
    "$report_app/Contents/Resources/native/ShotEyeSelector" --check-permission >/dev/null 2>&1 || report_permission_exit=$?
    report_display_read_exit=0
    "$report_app/Contents/Resources/native/ShotEyeSelector" --self-test-display-read >/dev/null 2>&1 || report_display_read_exit=$?
    printf 'Helper permission preflight exit: %s\n' "$report_permission_exit"
    printf 'Helper display-read self-test exit: %s\n' "$report_display_read_exit"
    if [ -n "${helper_capture_test_sha:-}" ]; then
      printf 'Helper capture-output self-test SHA-256: %s\n' "$helper_capture_test_sha"
      printf 'Helper capture-output self-test dimensions: %s\n' "$helper_capture_test_dimensions"
    fi
    report_selection_exit=0
    "$report_app/Contents/Resources/native/ShotEyeSelector" --self-test-selection >/dev/null 2>&1 || report_selection_exit=$?
    printf 'Helper selection reducer/AppKit event self-test exit: %s\n' "$report_selection_exit"
    if [ -f "$report_dmg" ]; then
      printf 'DMG path: %s\n' "$report_dmg"
      printf 'DMG SHA-256: %s\n' "$(shasum -a 256 "$report_dmg" | awk '{print $1}')"
    fi
    printf 'Canonical DMG path: %s\n' "$CANONICAL_DMG_PATH"
    printf 'Canonical DMG SHA-256: %s\n' "$(shasum -a 256 "$CANONICAL_DMG_PATH" | awk '{print $1}')"
    if [ -n "$ARTIFACT_PATH" ]; then
      printf 'Artifact path: %s\n' "$ARTIFACT_PATH"
      printf 'Artifact SHA-256: %s\n' "$(shasum -a 256 "$ARTIFACT_PATH" | awk '{print $1}')"
      printf 'Artifact PNG header: %s\n' "$(xxd -l 8 -p "$ARTIFACT_PATH")"
      printf 'Artifact dimensions: '
      sips -g pixelWidth -g pixelHeight "$ARTIFACT_PATH" 2>/dev/null | awk '/pixelWidth|pixelHeight/ {printf "%s%s", (seen++ ? "," : ""), $0} END {printf "\n"}'
    fi
  } > "$report_path"
  test -s "$report_path"
}

if [ -n "$REQUESTED_DMG_PATH" ] && [ "${SHOT_EYE_DMG_PAYLOAD:-0}" -ne 1 ]; then
  test -s "$REQUESTED_DMG_PATH"
  test -s "$CANONICAL_DMG_PATH"
  if ! cmp -s "$REQUESTED_DMG_PATH" "$CANONICAL_DMG_PATH"; then
    printf 'Requested ShotEye DMG is not byte-identical to the canonical download artifact: %s\n' "$CANONICAL_DMG_PATH" >&2
    exit 1
  fi
  MOUNT_DIR=$(mktemp -d -t shoteye-dmg)
  MOUNTED=0
  PAYLOAD_EXECUTABLE="$MOUNT_DIR/ShotEye.app/Contents/MacOS/shoteye"
  PAYLOAD_LAUNCHED=0
  cleanup_dmg() {
    if [ "$PAYLOAD_LAUNCHED" -eq 1 ]; then
      stop_exact_process "$PAYLOAD_EXECUTABLE" || true
    fi
    if [ "$MOUNTED" -eq 1 ]; then
      hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
    fi
    rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
  }
  trap cleanup_dmg EXIT INT TERM
  hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_DIR" "$REQUESTED_DMG_PATH" >/dev/null
  MOUNTED=1
  test -d "$MOUNT_DIR/ShotEye.app"
  if [ "$LAUNCH" -eq 1 ]; then
    # The installed app and the mounted payload share one bundle identifier,
    # so the single-instance plugin will route a mounted launch to the
    # installed process unless the exact installed test process is stopped.
    stop_exact_process "/Applications/ShotEye.app/Contents/MacOS/shoteye"
    PAYLOAD_LAUNCHED=1
    if [ -n "$ARTIFACT_PATH" ]; then
      if [ "$REQUIRE_RELEASE" -eq 1 ]; then
        SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh" --release --launch --artifact "$ARTIFACT_PATH"
      else
        SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh" --launch --artifact "$ARTIFACT_PATH"
      fi
    else
      if [ "$REQUIRE_RELEASE" -eq 1 ]; then
        SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh" --release --launch
      else
        SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh" --launch
      fi
    fi
  elif [ -n "$ARTIFACT_PATH" ]; then
    if [ "$REQUIRE_RELEASE" -eq 1 ]; then
      SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh" --release --artifact "$ARTIFACT_PATH"
    else
      SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh" --artifact "$ARTIFACT_PATH"
    fi
  else
    if [ "$REQUIRE_RELEASE" -eq 1 ]; then
      SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh" --release
    else
      SHOT_EYE_DMG_PAYLOAD_PATH="$MOUNT_DIR/ShotEye.app" SHOT_EYE_DMG_PAYLOAD=1 "$ROOT_DIR/scripts/verify_app.sh"
    fi
  fi
  if [ "$REQUIRE_RELEASE" -eq 1 ]; then
    if ! xcrun stapler validate "$REQUESTED_DMG_PATH"; then
      printf 'The release DMG has no valid stapled notarization ticket.\n' >&2
      exit 1
    fi
  fi
  run_helper_capture_self_test "$MOUNT_DIR/ShotEye.app/Contents/Resources/native/ShotEyeSelector"
  if [ -n "$REPORT_PATH" ]; then
    write_report "$REPORT_PATH" "$MOUNT_DIR/ShotEye.app" "$REQUESTED_DMG_PATH"
  fi
  cleanup_helper_capture_self_test
  printf 'ShotEye DMG payload verified: %s\n' "$REQUESTED_DMG_PATH"
  if [ -n "$REPORT_PATH" ]; then
    printf 'Report written: %s\n' "$REPORT_PATH"
  fi
  exit 0
fi

DMG_PATH=$BUILT_DMG_PATH
APP_EXECUTABLE="$APP_PATH/Contents/MacOS/shoteye"
HELPER="$APP_PATH/Contents/Resources/native/ShotEyeSelector"

test -d "$APP_PATH"
test -x "$APP_EXECUTABLE"
test -x "$HELPER"
test -x "$BUILT_APP/Contents/MacOS/shoteye"
test -x "$BUILT_APP/Contents/Resources/native/ShotEyeSelector"
test -n "$DMG_PATH"
test -s "$DMG_PATH"
test -s "$CANONICAL_DMG_PATH"
if ! cmp -s "$DMG_PATH" "$CANONICAL_DMG_PATH"; then
  printf 'Built ShotEye DMG is not byte-identical to the canonical download artifact: %s\n' "$CANONICAL_DMG_PATH" >&2
  exit 1
fi

if [ "$LAUNCH" -eq 1 ]; then
  /usr/bin/open -a "$APP_PATH"
  sleep 2
fi

bundle_executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Contents/Info.plist")
bundle_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist")
test "$bundle_executable" = shoteye
test "$bundle_identifier" = com.moltbagus.shoteye.tauri

if ! /usr/bin/file "$APP_EXECUTABLE" | /usr/bin/grep -q "Mach-O.*$EXPECTED_MACHO"; then
  printf 'Unexpected app architecture:\n' >&2
  /usr/bin/file "$APP_EXECUTABLE" >&2
  exit 1
fi
if ! /usr/bin/file "$HELPER" | /usr/bin/grep -q "Mach-O.*$EXPECTED_MACHO"; then
  printf 'Unexpected helper architecture:\n' >&2
  /usr/bin/file "$HELPER" >&2
  exit 1
fi

/usr/bin/codesign --verify --deep --strict "$APP_PATH"
test ! -e "$APP_PATH/Contents/MacOS/tauri-app"
cmp "$BUILT_APP/Contents/MacOS/shoteye" "$APP_EXECUTABLE"
cmp "$BUILT_APP/Contents/Resources/native/ShotEyeSelector" "$HELPER"

codesign --verify --strict "$HELPER"

if [ "$REQUIRE_RELEASE" -eq 1 ]; then
  APP_SIGNATURE_DETAILS=$(codesign --display --verbose=4 "$APP_PATH" 2>&1)
  if ! printf '%s\n' "$APP_SIGNATURE_DETAILS" | grep -Fq 'Authority=Developer ID Application:'; then
    printf 'Installed app is not signed by a Developer ID Application identity. Local/ad-hoc builds are not release-ready.\n' >&2
    exit 1
  fi
  APP_TEAM_IDENTIFIER=$(printf '%s\n' "$APP_SIGNATURE_DETAILS" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
  if [ -z "$APP_TEAM_IDENTIFIER" ] || [ "$APP_TEAM_IDENTIFIER" = "not set" ]; then
    printf 'Installed app does not contain a Developer ID TeamIdentifier.\n' >&2
    exit 1
  fi
  HELPER_SIGNATURE_DETAILS=$(codesign --display --verbose=4 "$HELPER" 2>&1)
  if ! printf '%s\n' "$HELPER_SIGNATURE_DETAILS" | grep -Fq 'Authority=Developer ID Application:'; then
    printf 'Bundled ShotEyeSelector is not signed by a Developer ID Application identity.\n' >&2
    exit 1
  fi
  HELPER_TEAM_IDENTIFIER=$(printf '%s\n' "$HELPER_SIGNATURE_DETAILS" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
  if [ "$HELPER_TEAM_IDENTIFIER" != "$APP_TEAM_IDENTIFIER" ]; then
    printf 'Bundled ShotEyeSelector TeamIdentifier does not match the app TeamIdentifier.\n' >&2
    exit 1
  fi
  if ! spctl --assess --type execute "$APP_PATH"; then
    printf 'Gatekeeper rejected the release app.\n' >&2
    exit 1
  fi
  if ! xcrun stapler validate "$APP_PATH"; then
    printf 'The release app has no valid stapled notarization ticket.\n' >&2
    exit 1
  fi
  if [ "${SHOT_EYE_DMG_PAYLOAD:-0}" -ne 1 ]; then
    if ! xcrun stapler validate "$DMG_PATH"; then
      printf 'The release DMG has no valid stapled notarization ticket.\n' >&2
      exit 1
    fi
  fi
fi

if [ "$LAUNCH" -eq 1 ]; then
  process_count=$(running_process_ids "$APP_EXECUTABLE" | /usr/bin/awk 'END {print NR + 0}')
  test "$process_count" -eq 1
fi

set +e
"$HELPER" --check-permission
helper_exit=$?
set -e
test "$helper_exit" -eq 0
"$HELPER" --self-test-geometry
"$HELPER" --self-test-mixed-dpi
"$HELPER" --self-test-crop-transform
"$HELPER" --self-test-selection
display_read_exit=0
"$HELPER" --self-test-display-read || display_read_exit=$?
test "$display_read_exit" -eq 0
run_helper_capture_self_test "$HELPER"

if [ -n "$ARTIFACT_PATH" ]; then
  test -s "$ARTIFACT_PATH"
  file_output=$(/usr/bin/file "$ARTIFACT_PATH")
  printf '%s\n' "$file_output" | /usr/bin/grep -q 'PNG image data'
  header=$(xxd -l 8 -p "$ARTIFACT_PATH")
  test "$header" = 89504e470d0a1a0a
  sips -g pixelWidth -g pixelHeight "$ARTIFACT_PATH"
fi

if [ -n "$REPORT_PATH" ]; then
  write_report "$REPORT_PATH" "$APP_PATH" "$DMG_PATH"
fi

cleanup_helper_capture_self_test

printf 'ShotEye package verified: %s\n' "$APP_PATH"
printf 'DMG verified: %s\n' "$DMG_PATH"
if [ "$REQUIRE_RELEASE" -eq 1 ]; then
  printf '%s\n' 'Release gates: Developer ID, matching TeamIdentifier, Gatekeeper, and stapled notarization passed'
else
  printf '%s\n' 'Release gates: not evaluated (local-only verification)'
fi
printf 'Bundle: %s (%s)\n' "$bundle_executable" "$bundle_identifier"
printf 'Architecture: %s\n' "$EXPECTED_MACHO"
printf 'Helper permission probe: exit %s\n' "$helper_exit"
printf '%s\n' 'Helper geometry self-test: passed'
printf '%s\n' 'Helper mixed-DPI compositor self-test: passed'
printf '%s\n' 'Helper crop transform self-test: passed'
printf '%s\n' 'Helper selection reducer/AppKit event self-test: passed'
printf 'Helper display-read self-test: exit %s\n' "$display_read_exit"
printf 'Helper capture-output self-test: passed (%s, SHA-256 %s)\n' "$helper_capture_test_dimensions" "$helper_capture_test_sha"
if [ -n "$REPORT_PATH" ]; then
  printf 'Report written: %s\n' "$REPORT_PATH"
fi

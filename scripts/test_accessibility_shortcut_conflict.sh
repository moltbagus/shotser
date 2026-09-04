#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_PATH=/Applications/ShotEye.app
REPORT_PATH="$ROOT_DIR/artifacts/tauri-e2e/shortcut-conflict-acceptance.txt"
FIXTURE_SOURCE="$ROOT_DIR/scripts/shortcut_conflict_fixture.swift"
AX_SOURCE="$ROOT_DIR/scripts/shoteye_ax_driver.swift"
BUILD_DIR="${TMPDIR:-/tmp}/shoteye-shortcut-conflict-$$"
FIXTURE_BINARY="$BUILD_DIR/shortcut-conflict-fixture"
AX_BINARY="$BUILD_DIR/shoteye-ax-driver"
FIXTURE_LOG="$BUILD_DIR/fixture.log"
fixture_pid=""
process_pid=""

mkdir -p "$(dirname "$REPORT_PATH")" "$BUILD_DIR"

write_report() {
  result=$1
  detail=$2
  {
    printf '%s\n' 'ShotEye packaged Accessibility shortcut-conflict acceptance'
    printf 'Generated (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'App path: %s\n' "$APP_PATH"
    printf 'Fixture shortcut: Command+Alt+F18\n'
    printf 'Result: %s\n' "$result"
    printf 'Detail: %s\n' "$detail"
  } > "$REPORT_PATH"
}

cleanup() {
  if [ -n "$process_pid" ] && [ -x "$AX_BINARY" ]; then
    "$AX_BINARY" --pid "$process_pid" --find "Reset capture shortcut to default" --press --timeout 1 >/dev/null 2>&1 || true
  fi
  if [ -n "$fixture_pid" ] && kill -0 "$fixture_pid" >/dev/null 2>&1; then
    kill -TERM "$fixture_pid" >/dev/null 2>&1 || true
    wait "$fixture_pid" >/dev/null 2>&1 || true
  fi
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT INT TERM

if [ ! -d "$APP_PATH" ]; then
  write_report BLOCKED 'The exact installed ShotEye app is missing.'
  exit 2
fi
if ! command -v swiftc >/dev/null 2>&1; then
  write_report BLOCKED 'swiftc is unavailable; the stable AX and isolated fixture drivers cannot run.'
  exit 2
fi

preflight_report="$ROOT_DIR/artifacts/tauri-e2e/shortcut-conflict-preflight.txt"
if ! "$ROOT_DIR/scripts/verify_ui_smoke.sh" --report "$preflight_report" >/dev/null 2>&1; then
  write_report BLOCKED "Packaged Accessibility preflight did not pass; see $preflight_report."
  exit 2
fi

fixture_probe_output=""
fixture_probe_exit=0
fixture_probe_output=$("$ROOT_DIR/scripts/test_shortcut_conflict_fixture.sh" --check-exclusive 2>&1) || fixture_probe_exit=$?
if [ "$fixture_probe_exit" -eq 2 ]; then
  write_report BLOCKED "The shortcut fixture could not prove exclusive ownership on this host; no ShotEye conflict claim was made. See $ROOT_DIR/artifacts/tauri-e2e/shortcut-conflict-fixture.txt. $fixture_probe_output"
  exit 2
fi
if [ "$fixture_probe_exit" -ne 0 ]; then
  write_report FAIL "The shortcut fixture self-test failed unexpectedly: $fixture_probe_output"
  exit 1
fi

swiftc "$AX_SOURCE" -o "$AX_BINARY"
swiftc "$FIXTURE_SOURCE" -o "$FIXTURE_BINARY"
process_pid=$(/bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$APP_PATH/Contents/MacOS/shoteye" '$2 == expected {print $1; exit}')
if [ -z "$process_pid" ]; then
  write_report BLOCKED 'The canonical ShotEye process disappeared after preflight.'
  exit 2
fi

# The previous run may have intentionally left a custom shortcut selected.
# Start each acceptance from the known default so conflict evidence is not
# contaminated by persisted state from another run.
"$AX_BINARY" --pid "$process_pid" --find "Reset capture shortcut to default" --press --timeout 4 >/dev/null
sleep 0.5

"$FIXTURE_BINARY" > "$FIXTURE_LOG" 2>&1 &
fixture_pid=$!
fixture_ready=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if /usr/bin/grep -q '^RESERVED' "$FIXTURE_LOG"; then
    fixture_ready=1
    break
  fi
  if ! kill -0 "$fixture_pid" >/dev/null 2>&1; then break; fi
  sleep 0.2
done
if [ "$fixture_ready" -ne 1 ]; then
  fixture_detail=$(/bin/cat "$FIXTURE_LOG" 2>/dev/null || true)
  write_report BLOCKED "The isolated fixture could not reserve its chord: $fixture_detail"
  exit 2
fi

record_output=""
record_exit=0
record_output=$("$AX_BINARY" --pid "$process_pid" --find "Record capture shortcut" --press --timeout 4 2>&1) || record_exit=$?
if [ "$record_exit" -ne 0 ]; then
  write_report BLOCKED "Stable AX driver could not activate shortcut recording: $record_output"
  exit 2
fi

focus_output=""
focus_exit=0
focus_output=$(/usr/bin/perl -e 'alarm 15; exec @ARGV' /usr/bin/osascript -e 'tell application "System Events" to tell process "shoteye" to set frontmost to true' 2>&1) || focus_exit=$?
if [ "$focus_exit" -ne 0 ]; then
  write_report BLOCKED "Accessibility could not focus ShotEye before delivering the reserved shortcut: $focus_output"
  exit 2
fi

key_output=""
key_exit=0
key_output=$("$AX_BINARY" --post-f18 2>&1) || key_exit=$?
if [ "$key_exit" -ne 0 ]; then
  write_report BLOCKED "Accessibility could not deliver the reserved shortcut: $key_output"
  exit 2
fi
sleep 1

status_output=$(/usr/bin/perl -e 'alarm 15; exec @ARGV' /usr/bin/osascript <<'APPLESCRIPT' 2>&1
on run
  tell application "System Events"
    if not (exists process "shoteye") then error "ShotEye process is not running."
    tell process "shoteye"
      if not (exists window 1) then error "ShotEye has no editor window."
      set contentList to entire contents of window 1
      set names to {}
      repeat with candidate in contentList
        try
          set candidateName to name of candidate as text
          if candidateName is not "" then set end of names to candidateName
        end try
      end repeat
      return names as text
    end tell
  end tell
end run
APPLESCRIPT
)
if ! printf '%s' "$status_output" | /usr/bin/grep -q 'Conflict'; then
  write_report FAIL "ShotEye did not expose Conflict after the fixture reserved the requested chord. AX record=$record_output; surface=$status_output"
  exit 1
fi

reset_output=""
reset_exit=0
reset_output=$("$AX_BINARY" --pid "$process_pid" --find "Reset capture shortcut to default" --press --timeout 4 2>&1) || reset_exit=$?
if [ "$reset_exit" -ne 0 ]; then
  write_report FAIL "ShotEye reported conflict but the stable AX driver could not reset the default binding: $reset_output"
  exit 1
fi
sleep 1
reset_status=$(/usr/bin/perl -e 'alarm 15; exec @ARGV' /usr/bin/osascript <<'APPLESCRIPT' 2>&1
on run
  tell application "System Events"
    tell process "shoteye"
      set contentList to entire contents of window 1
      set names to {}
      repeat with candidate in contentList
        try
          set candidateName to name of candidate as text
          if candidateName is not "" then set end of names to candidateName
        end try
      end repeat
      return names as text
    end tell
  end tell
end run
APPLESCRIPT
)
if ! printf '%s' "$reset_status" | /usr/bin/grep -q 'Active'; then
  write_report FAIL "ShotEye did not return to Active after default reset. AX reset=$reset_output; surface=$reset_status"
  exit 1
fi

write_report PASS "Direct AX record/reset passed; conflict state and default recovery were observed; fixture cleanup is enforced by trap. Preflight: $preflight_report."
printf 'ShotEye shortcut-conflict acceptance passed. Report written: %s\n' "$REPORT_PATH"

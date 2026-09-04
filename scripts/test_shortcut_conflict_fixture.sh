#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE_PATH="$ROOT_DIR/scripts/shortcut_conflict_fixture.swift"
BUILD_DIR=${TMPDIR:-/tmp}/shoteye-shortcut-fixture
BINARY_PATH="$BUILD_DIR/shortcut-conflict-fixture"
REPORT_PATH="$ROOT_DIR/artifacts/tauri-e2e/shortcut-conflict-fixture.txt"
CHECK_EXCLUSIVE=0
if [ "$#" -gt 0 ]; then
  if [ "$1" = "--check-exclusive" ] && [ "$#" -eq 1 ]; then
    CHECK_EXCLUSIVE=1
  else
    printf '%s\n' 'Usage: test_shortcut_conflict_fixture.sh [--check-exclusive]' >&2
    exit 2
  fi
fi

mkdir -p "$BUILD_DIR" "$(dirname "$REPORT_PATH")"
if ! command -v swiftc >/dev/null 2>&1; then
  printf '%s\n' 'BLOCKED: swiftc is unavailable; cannot create the isolated shortcut fixture.' | tee "$REPORT_PATH"
  exit 2
fi

swiftc "$SOURCE_PATH" -o "$BINARY_PATH"
fixture_log="$BUILD_DIR/fixture.log"
second_log="$BUILD_DIR/second.log"
fixture_exit=0
"$BINARY_PATH" > "$fixture_log" 2>&1 &
fixture_pid=$!
second_pid=""

cleanup() {
  if kill -0 "$fixture_pid" >/dev/null 2>&1; then
    kill -TERM "$fixture_pid" >/dev/null 2>&1 || true
    wait "$fixture_pid" >/dev/null 2>&1 || true
  fi
  if [ -n "$second_pid" ] && kill -0 "$second_pid" >/dev/null 2>&1; then
    kill -TERM "$second_pid" >/dev/null 2>&1 || true
    wait "$second_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

reserved=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if /usr/bin/grep -q '^RESERVED' "$fixture_log"; then
    reserved=1
    break
  fi
  if ! kill -0 "$fixture_pid" >/dev/null 2>&1; then break; fi
  sleep 0.2
done

if [ "$reserved" -ne 1 ]; then
  wait "$fixture_pid" >/dev/null 2>&1 || fixture_exit=$?
  fixture_output=$(/bin/cat "$fixture_log" 2>/dev/null || true)
  {
    printf '%s\n' 'ShotEye isolated shortcut fixture report'
    printf 'Result: BLOCKED\n'
    printf 'Fixture: Command+Alt+F18\n'
    printf 'Detail: %s\n' "$fixture_output"
    printf 'Cleanup: not required; fixture exited before reservation.\n'
  } > "$REPORT_PATH"
  printf 'Shortcut fixture blocked: %s\n' "$fixture_output" >&2
  exit 2
fi

if [ "$CHECK_EXCLUSIVE" -eq 1 ]; then
  "$BINARY_PATH" > "$second_log" 2>&1 &
  second_pid=$!
  second_reserved=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if /usr/bin/grep -q '^RESERVED' "$second_log"; then
      second_reserved=1
      break
    fi
    if ! kill -0 "$second_pid" >/dev/null 2>&1; then break; fi
    sleep 0.2
  done
  if [ "$second_reserved" -eq 1 ]; then
    second_output=$(/bin/cat "$second_log" 2>/dev/null || true)
    write_detail="macOS accepted a second reservation for the same chord; the Carbon fixture is not an exclusive conflict owner. First=$(/bin/cat "$fixture_log"); Second=$second_output"
    kill -TERM "$second_pid" >/dev/null 2>&1 || true
    wait "$second_pid" >/dev/null 2>&1 || true
    kill -TERM "$fixture_pid" >/dev/null 2>&1 || true
    wait "$fixture_pid" >/dev/null 2>&1 || true
    {
      printf '%s\n' 'ShotEye isolated shortcut fixture report'
      printf 'Result: BLOCKED\n'
      printf 'Fixture: Command+Alt+F18\n'
      printf 'Detail: %s\n' "$write_detail"
      printf 'Cleanup: both fixture processes terminated; no exclusive reservation was claimed.\n'
    } > "$REPORT_PATH"
    printf 'Shortcut fixture blocked: reservation is not exclusive on this macOS host.\n' >&2
    exit 2
  fi
  wait "$second_pid" >/dev/null 2>&1 || true
  second_pid=""
fi

kill -TERM "$fixture_pid" >/dev/null 2>&1 || true
wait "$fixture_pid" >/dev/null 2>&1 || fixture_exit=$?
if kill -0 "$fixture_pid" >/dev/null 2>&1; then
  printf '%s\n' 'Shortcut fixture cleanup failed.' >&2
  exit 1
fi

{
  printf '%s\n' 'ShotEye isolated shortcut fixture report'
  printf 'Result: PASS\n'
  printf 'Fixture: Command+Alt+F18\n'
  printf 'Reservation: process started and owned the chord.\n'
  printf 'Cleanup: process terminated and reservation released.\n'
} > "$REPORT_PATH"
printf 'Shortcut fixture passed. Report written: %s\n' "$REPORT_PATH"

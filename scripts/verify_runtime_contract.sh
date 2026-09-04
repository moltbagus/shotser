#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_PATH=${SHOT_EYE_RUNTIME_APP:-/Applications/ShotEye.app}
REPORT_PATH=${1:-$ROOT_DIR/artifacts/tauri-e2e/runtime-contract.txt}
TRACE_PATH=${REPORT_PATH%.*}.trace
REPORT_DIR=$(dirname "$REPORT_PATH")
LOG_PATH=$(mktemp -t shoteye-runtime-contract).log
RUNTIME_PID=""

cleanup_runtime() {
  if [ -n "$RUNTIME_PID" ]; then
    if kill -0 "$RUNTIME_PID" 2>/dev/null; then
      kill -TERM "$RUNTIME_PID" 2>/dev/null || true
      wait "$RUNTIME_PID" 2>/dev/null || true
    fi
  fi
  rm -f "$LOG_PATH"
}
trap cleanup_runtime EXIT HUP INT TERM

if [ ! -d "$APP_PATH" ]; then
  printf 'ShotEye app not found: %s\n' "$APP_PATH" >&2
  exit 1
fi
APP_EXECUTABLE="$APP_PATH/Contents/MacOS/shoteye"
if [ ! -x "$APP_EXECUTABLE" ]; then
  printf 'ShotEye executable not found: %s\n' "$APP_EXECUTABLE" >&2
  exit 1
fi
/usr/bin/codesign --verify --deep --strict "$APP_PATH"
mkdir -p "$REPORT_DIR"
rm -f "$REPORT_PATH" "$TRACE_PATH"

running_pids() {
  /bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$APP_EXECUTABLE" '$2 == expected { print $1 }'
}

stop_existing_runtime_app() {
  pids=$(running_pids)
  [ -z "$pids" ] && return 0
  for pid in $pids; do
    /bin/kill -TERM "$pid" 2>/dev/null || true
  done
  attempts=0
  while [ "$attempts" -lt 40 ]; do
    pids=$(running_pids)
    [ -z "$pids" ] && return 0
    /bin/sleep 0.05
    attempts=$((attempts + 1))
  done
  for pid in $pids; do
    /bin/kill -KILL "$pid" 2>/dev/null || true
  done
  pids=$(running_pids)
  if [ -n "$pids" ]; then
    printf 'Could not stop the existing exact ShotEye test process.\n' >&2
    exit 1
  fi
}

stop_existing_runtime_app
SHOT_EYE_RUNTIME_CONTRACT=1 SHOT_EYE_RUNTIME_CONTRACT_REPORT="$REPORT_PATH" "$APP_EXECUTABLE" >"$LOG_PATH" 2>&1 &
RUNTIME_PID=$!

attempts=0
while [ "$attempts" -lt 120 ]; do
  if [ -s "$REPORT_PATH" ] && /usr/bin/grep -Fq 'Result: PASS' "$REPORT_PATH"; then
    break
  fi
  if ! kill -0 "$RUNTIME_PID" 2>/dev/null; then
    printf 'ShotEye runtime contract process exited before producing a passing report.\n' >&2
    cat "$LOG_PATH" >&2
    [ ! -s "$REPORT_PATH" ] || cat "$REPORT_PATH" >&2
    exit 1
  fi
  /bin/sleep 0.25
  attempts=$((attempts + 1))
done

if [ ! -s "$REPORT_PATH" ] || ! /usr/bin/grep -Fq 'Result: PASS' "$REPORT_PATH"; then
  printf 'ShotEye packaged runtime contract did not pass within 30 seconds.\n' >&2
  cat "$LOG_PATH" >&2
  [ ! -s "$REPORT_PATH" ] || cat "$REPORT_PATH" >&2
  exit 1
fi

/usr/bin/grep -Fq 'Frontend ready: true' "$REPORT_PATH"
/usr/bin/grep -Fq 'Capture IPC action succeeded: true' "$REPORT_PATH"
/usr/bin/grep -Fq 'Window restoration succeeded: true' "$REPORT_PATH"
/usr/bin/grep -Fq 'Capture activity released: true' "$REPORT_PATH"
printf 'ShotEye packaged runtime contract passed: %s\n' "$REPORT_PATH"

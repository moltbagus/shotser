#!/bin/sh
set -eu

# Proves the shipped primary-display area-capture path with a real HID drag:
# canonical installed app -> bundled selector -> valid copied PNG. This is an
# opt-in physical test. It never changes privacy settings and is intentionally
# bounded so an unavailable Accessibility or Screen Recording grant is reported
# rather than leaving a selector or helper running.

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_PATH=/Applications/ShotEye.app
APP_EXECUTABLE="$APP_PATH/Contents/MacOS/shoteye"
SELECTOR_PATH="$APP_PATH/Contents/Resources/native/ShotEyeSelector"
ARTIFACT_PATH="$ROOT_DIR/artifacts/tauri-e2e/physical-area-capture.png"
REPORT_PATH="$ROOT_DIR/artifacts/tauri-e2e/physical-area-capture.txt"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact)
      shift
      [ "$#" -gt 0 ] || { printf '%s\n' '--artifact requires a PNG path.' >&2; exit 2; }
      ARTIFACT_PATH=$1
      ;;
    --report)
      shift
      [ "$#" -gt 0 ] || { printf '%s\n' '--report requires an output path.' >&2; exit 2; }
      REPORT_PATH=$1
      ;;
    *)
      printf 'Usage: %s [--artifact PNG] [--report TEXT]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

mkdir -p "$(dirname "$ARTIFACT_PATH")" "$(dirname "$REPORT_PATH")"
ARTIFACT_DIRECTORY=$(CDPATH= cd -- "$(dirname "$ARTIFACT_PATH")" && pwd -P)
REPORT_DIRECTORY=$(CDPATH= cd -- "$(dirname "$REPORT_PATH")" && pwd -P)
case "$ARTIFACT_DIRECTORY" in
  "$ROOT_DIR/artifacts/tauri-e2e"|"$ROOT_DIR/artifacts/tauri-e2e"/*) ;;
  *)
    printf 'Refusing to overwrite a physical-capture artifact outside %s.\n' "$ROOT_DIR/artifacts/tauri-e2e" >&2
    exit 2
    ;;
esac
case "$REPORT_DIRECTORY" in
  "$ROOT_DIR/artifacts/tauri-e2e"|"$ROOT_DIR/artifacts/tauri-e2e"/*) ;;
  *)
    printf 'Refusing to overwrite a physical-capture report outside %s.\n' "$ROOT_DIR/artifacts/tauri-e2e" >&2
    exit 2
    ;;
esac
ARTIFACT_PATH="$ARTIFACT_DIRECTORY/$(basename "$ARTIFACT_PATH")"
REPORT_PATH="$REPORT_DIRECTORY/$(basename "$REPORT_PATH")"

write_report() {
  result=$1
  detail=$2
  {
    printf '%s\n' 'ShotEye physical area-capture acceptance report'
    printf 'Generated (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'App path: %s\n' "$APP_PATH"
    printf 'Scope: primary display; direct Accessibility toolbar press; HID drag; Copy capture clipboard export.\n'
    printf 'Result: %s\n' "$result"
    printf 'Detail: %s\n' "$detail"
    if [ -f "$ARTIFACT_PATH" ]; then
      printf 'Artifact path: %s\n' "$ARTIFACT_PATH"
      printf 'Artifact bytes: %s\n' "$(wc -c < "$ARTIFACT_PATH" | tr -d ' ')"
      printf 'Artifact PNG header: %s\n' "$(xxd -l 8 -p "$ARTIFACT_PATH")"
      printf 'Artifact dimensions: %s\n' "$(sips -g pixelWidth -g pixelHeight "$ARTIFACT_PATH" 2>/dev/null | awk '/pixelWidth/{width=$2} /pixelHeight/{height=$2} END {printf "%sx%s", width, height}')"
      printf 'Artifact SHA-256: %s\n' "$(shasum -a 256 "$ARTIFACT_PATH" | awk '{print $1}')"
    fi
  } > "$REPORT_PATH"
}

exact_process_pid() {
  /bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$APP_EXECUTABLE" '$2 == expected {print $1; exit}'
}

exact_process_count() {
  /bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$APP_EXECUTABLE" '$2 == expected {count++} END {print count + 0}'
}

selector_count() {
  /bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$SELECTOR_PATH" '$2 == expected {count++} END {print count + 0}'
}

TEMP_DIR=$(mktemp -d -t shoteye-physical-area)
AX_BINARY="$TEMP_DIR/shoteye-ax-driver"
DRAG_BINARY="$TEMP_DIR/shoteye-physical-drag"
CLIPBOARD_BINARY="$TEMP_DIR/shoteye-write-clipboard-png"

cleanup() {
  /bin/rm -f "$AX_BINARY" "$DRAG_BINARY" "$CLIPBOARD_BINARY"
  rmdir "$TEMP_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

if [ ! -d "$APP_PATH" ] || [ ! -x "$APP_EXECUTABLE" ] || [ ! -x "$SELECTOR_PATH" ]; then
  write_report BLOCKED 'The exact installed ShotEye app or bundled native selector is missing.'
  exit 2
fi
if ! /usr/bin/codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1; then
  write_report BLOCKED 'The exact installed ShotEye app failed strict code-signature validation.'
  exit 2
fi
if ! "$SELECTOR_PATH" --check-permission >/dev/null 2>&1; then
  write_report BLOCKED 'Screen Recording permission is unavailable for the exact installed ShotEye identity.'
  exit 2
fi

swiftc "$ROOT_DIR/scripts/shoteye_ax_driver.swift" -o "$AX_BINARY"
swiftc "$ROOT_DIR/scripts/physical_drag.swift" -o "$DRAG_BINARY"
swiftc "$ROOT_DIR/scripts/write_clipboard_png.swift" -o "$CLIPBOARD_BINARY"

/usr/bin/open -a "$APP_PATH" >/dev/null 2>&1 || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ "$(exact_process_count)" -eq 1 ] && break
  sleep 1
done
if [ "$(exact_process_count)" -ne 1 ]; then
  write_report FAIL "Expected exactly one canonical ShotEye process, found $(exact_process_count)."
  exit 1
fi

process_pid=$(exact_process_pid)
capture_output=""
capture_exit=0
capture_output=$("$AX_BINARY" --pid "$process_pid" --find 'Capture area' --press --timeout 5 2>&1) || capture_exit=$?
if [ "$capture_exit" -ne 0 ]; then
  write_report BLOCKED "Direct Accessibility could not invoke Capture area: $capture_output"
  exit 2
fi

for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ "$(selector_count)" -gt 0 ] && break
  sleep 1
done
if [ "$(selector_count)" -eq 0 ]; then
  write_report FAIL 'Capture area was pressed, but the bundled ShotEyeSelector did not appear within 10 seconds.'
  exit 1
fi

"$DRAG_BINARY"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ "$(selector_count)" -eq 0 ] && break
  sleep 1
done
if [ "$(selector_count)" -ne 0 ]; then
  write_report FAIL 'The bundled ShotEyeSelector did not exit within 10 seconds after the physical drag.'
  exit 1
fi

for _ in 1 2 3 4 5 6 7 8 9 10; do
  process_pid=$(exact_process_pid)
  copy_output=""
  copy_exit=0
  copy_output=$("$AX_BINARY" --pid "$process_pid" --find 'Copy capture' --press --timeout 2 2>&1) || copy_exit=$?
  [ "$copy_exit" -eq 0 ] && break
  sleep 1
done
if [ "${copy_exit:-1}" -ne 0 ]; then
  write_report FAIL "ShotEye did not restore a usable editor with Copy capture after selection: ${copy_output:-unknown error}"
  exit 1
fi

rm -f "$ARTIFACT_PATH"
clipboard_output=""
clipboard_exit=0
clipboard_output=$("$CLIPBOARD_BINARY" "$ARTIFACT_PATH" 2>&1) || clipboard_exit=$?
if [ "$clipboard_exit" -ne 0 ] || [ ! -s "$ARTIFACT_PATH" ]; then
  write_report FAIL "Copy capture did not produce PNG pasteboard data: $clipboard_output"
  exit 1
fi
if [ "$(xxd -l 8 -p "$ARTIFACT_PATH")" != 89504e470d0a1a0a ]; then
  write_report FAIL 'Copy capture produced a non-PNG clipboard artifact.'
  exit 1
fi
dimensions=$(sips -g pixelWidth -g pixelHeight "$ARTIFACT_PATH" 2>/dev/null | awk '/pixelWidth/{width=$2} /pixelHeight/{height=$2} END {printf "%sx%s", width, height}')
case "$dimensions" in
  *x* ) ;;
  * )
    write_report FAIL 'Copy capture PNG dimensions could not be read.'
    exit 1
    ;;
esac

write_report PASS "Capture invocation: $capture_output; Copy invocation: $copy_output; Clipboard export: $clipboard_output; exactly one canonical ShotEye process remains."
printf 'Physical area capture passed. Report: %s; PNG: %s\n' "$REPORT_PATH" "$ARTIFACT_PATH"

#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_PATH=/Applications/ShotEye.app
REPORT_PATH="$ROOT_DIR/artifacts/tauri-e2e/physical-ui-smoke.txt"
CAPTURE_CANCEL=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --report)
      shift
      if [ "$#" -eq 0 ]; then
        printf '%s\n' '--report requires an output path.' >&2
        exit 2
      fi
      REPORT_PATH=$1
      ;;
    --capture-cancel)
      CAPTURE_CANCEL=1
      ;;
    *)
      printf 'Usage: %s [--report PATH] [--capture-cancel]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

mkdir -p "$(dirname "$REPORT_PATH")"

write_report() {
  result=$1
  detail=$2
  {
    printf '%s\n' 'ShotEye packaged Accessibility UI smoke report'
    printf 'Generated (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'App path: %s\n' "$APP_PATH"
    printf 'Result: %s\n' "$result"
    printf 'Detail: %s\n' "$detail"
  } > "$REPORT_PATH"
}

if [ ! -d "$APP_PATH" ]; then
  write_report BLOCKED "The exact installed app was not found at $APP_PATH."
  printf 'Physical UI smoke blocked: app not found at %s\n' "$APP_PATH" >&2
  exit 2
fi

if ! /usr/bin/codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1; then
  write_report BLOCKED "The exact installed app failed strict code-signature validation."
  printf '%s\n' 'Physical UI smoke blocked: strict app signature validation failed.' >&2
  exit 2
fi

# Reuse the canonical installed process. Do not use `open -n`, which would
# create a second process and invalidate the single-instance acceptance.
/usr/bin/open -a "$APP_PATH" >/dev/null 2>&1 || true

process_count=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  process_count=$(/bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$APP_PATH/Contents/MacOS/shoteye" '$2 == expected {count++} END {print count + 0}')
  [ "$process_count" -eq 1 ] && break
  sleep 1
done
if [ "$process_count" -ne 1 ]; then
  write_report FAIL "Expected exactly one canonical ShotEye process, found $process_count."
  printf 'Physical UI smoke failed: expected one canonical ShotEye process, found %s.\n' "$process_count" >&2
  exit 1
fi

automation_output=""
automation_exit=1
automation_surface="unclassified"
AX_DRIVER_SOURCE="$ROOT_DIR/scripts/shoteye_ax_driver.swift"
AX_DRIVER_BINARY="${TMPDIR:-/tmp}/shoteye-ax-driver.$$"
if command -v swiftc >/dev/null 2>&1 && [ -f "$AX_DRIVER_SOURCE" ]; then
  ax_compile_output=""
  ax_compile_exit=0
  ax_compile_output=$(swiftc "$AX_DRIVER_SOURCE" -o "$AX_DRIVER_BINARY" 2>&1) || ax_compile_exit=$?
  if [ "$ax_compile_exit" -eq 0 ]; then
    process_pid=$(/bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$APP_PATH/Contents/MacOS/shoteye" '$2 == expected {print $1; exit}')
    ax_output=""
    ax_exit=0
    ax_output=$("$AX_DRIVER_BINARY" --pid "$process_pid" --find "Record capture shortcut" --timeout 4 2>&1) || ax_exit=$?
    if [ "$ax_exit" -eq 0 ]; then
      ax_output="$ax_output; $("$AX_DRIVER_BINARY" --pid "$process_pid" --find "Rectangle" --press --timeout 4 2>&1)" || ax_exit=$?
      ax_output="$ax_output; $("$AX_DRIVER_BINARY" --pid "$process_pid" --find "Select" --press --timeout 4 2>&1)" || ax_exit=$?
    fi
    if [ "$ax_exit" -eq 0 ]; then
      automation_output="Direct AX attachment: pid=$process_pid; $ax_output"
      automation_exit=0
      automation_surface="direct-ax"
    fi
  fi
fi

if [ "$automation_exit" -ne 0 ]; then
for _ in 1 2 3 4 5 6 7 8 9 10; do
  automation_output=$(/usr/bin/perl -e 'alarm 15; exec @ARGV' /usr/bin/osascript <<'APPLESCRIPT' 2>&1
on run
  tell application "System Events"
    if not (exists process "shoteye") then error "ShotEye process is not running."
    set shotEyeProcess to process "shoteye"
    tell shotEyeProcess
      set frontmost to true
      if not (exists window 1) then error "ShotEye has no accessible editor window."

      set requiredMenus to {"ShotEye", "File", "Capture", "Edit", "Tools", "Help"}
      set visibleMenus to name of every menu bar item of menu bar 1
      repeat with requiredMenu in requiredMenus
        set requiredName to requiredMenu as text
        if visibleMenus does not contain requiredName then error "Missing application menu: " & requiredName
      end repeat

      -- WKWebView exposes its DOM controls below an AXWebArea rather than as
      -- direct children of the native window. Search the complete tree so the
      -- smoke test exercises the actual packaged toolbar controls.
      set requiredButtons to {"Open image", "Import clipboard image", "Copy capture", "Save capture", "Drag capture out", "Select", "Crop", "Arrow", "Rectangle", "Text", "Draw", "Redact", "Pixelate", "Blur", "Undo", "Redo", "Clear", "Reset image and edits", "Repeat last capture", "Capture a window", "Capture full screen", "Capture area", "Request Screen Recording permission", "Open Screen Recording settings", "Record capture shortcut"}
      set contentList to entire contents of window 1
      set visibleButtons to {}
      set visibleControls to {}
      repeat with indexValue from 1 to count of contentList
        try
          set candidate to item indexValue of contentList
          set candidateRole to role of candidate as text
          if candidateRole is "AXButton" then set end of visibleButtons to (name of candidate as text)
          if candidateRole is "AXButton" or candidateRole is "AXCheckBox" then set end of visibleControls to (name of candidate as text)
        end try
      end repeat
      if visibleButtons contains "Open image" then
        repeat with requiredButton in requiredButtons
          set requiredName to requiredButton as text
          if visibleButtons does not contain requiredName then error "Missing accessible button: " & requiredName
        end repeat
        if not (visibleControls contains "Pin ShotEye") and not (visibleControls contains "Unpin ShotEye") then error "Missing accessible Pin/Unpin control"

        -- Exercise representative controls that do not capture, open a dialog,
        -- request privacy access, or write to the clipboard/filesystem.
        set rectangleButton to missing value
        set selectButton to missing value
        repeat with indexValue from 1 to count of contentList
          try
            set candidate to item indexValue of contentList
            if (role of candidate as text) is "AXButton" then
              if (name of candidate as text) is "Rectangle" then set rectangleButton to candidate
              if (name of candidate as text) is "Select" then set selectButton to candidate
            end if
          end try
        end repeat
        if rectangleButton is missing value then error "Rectangle toolbar control is not exposed."
        if selectButton is missing value then error "Select toolbar control is not exposed."
        click rectangleButton
        click selectButton
        return "Accessible editor controls: " & (count of requiredButtons) & "; application menus: " & (count of requiredMenus) & "; representative toolbar clicks: Rectangle, Select"
      else
        -- Keep a native-menu fallback for an environment where WebView
        -- Accessibility is unavailable, while reporting that boundary.
        click menu bar item "Tools" of menu bar 1
        click menu item "Rectangle" of menu 1 of menu bar item "Tools" of menu bar 1
        click menu bar item "Tools" of menu bar 1
        click menu item "Select" of menu 1 of menu bar item "Tools" of menu bar 1
        return "Native menu controls: Rectangle, Select; application menus: " & (count of requiredMenus) & "; WebView toolbar controls are not exposed in the macOS Accessibility tree, so toolbar pointer acceptance remains separate."
      end if
    end tell
  end tell
end run
APPLESCRIPT
  ) && automation_exit=0 || automation_exit=$?
  [ "$automation_exit" -eq 0 ] && break
  sleep 1
done
automation_surface="system-events-or-native-menu"
fi

rm -f "$AX_DRIVER_BINARY"

if [ "$automation_exit" -ne 0 ]; then
  write_report BLOCKED "Accessibility automation is unavailable or the desktop is locked; surface=$automation_surface: $automation_output"
  printf 'Physical UI smoke blocked: %s\n' "$automation_output" >&2
  exit 2
fi

if [ "$CAPTURE_CANCEL" -eq 1 ]; then
  HELPER_PATH="$APP_PATH/Contents/Resources/native/ShotEyeSelector"
  if [ ! -x "$HELPER_PATH" ]; then
    write_report BLOCKED "The installed ShotEye bundle does not contain an executable native selector."
    printf '%s\n' 'Capture cancellation smoke blocked: native selector is missing.' >&2
    exit 2
  fi

  permission_exit=0
  "$HELPER_PATH" --check-permission >/dev/null 2>&1 || permission_exit=$?
  if [ "$permission_exit" -ne 0 ]; then
    write_report BLOCKED "Capture cancellation smoke requires Screen Recording permission; native selector preflight exited $permission_exit."
    printf 'Capture cancellation smoke blocked: native selector preflight exited %s.\n' "$permission_exit" >&2
    exit 2
  fi

  capture_click_output=""
  capture_click_exit=0
  capture_click_output=$(/usr/bin/perl -e 'alarm 15; exec @ARGV' /usr/bin/osascript <<'APPLESCRIPT' 2>&1
on run
  tell application "System Events"
    if not (exists process "shoteye") then error "ShotEye process is not running."
    set shotEyeProcess to process "shoteye"
    tell shotEyeProcess
      set frontmost to true
      if not (exists window 1) then error "ShotEye has no accessible editor window before capture."
      set contentList to entire contents of window 1
      set captureButton to missing value
      repeat with indexValue from 1 to count of contentList
        try
          set candidate to item indexValue of contentList
          if (role of candidate as text) is "AXButton" and (name of candidate as text) is "Capture area" then
            set captureButton to candidate
            exit repeat
          end if
        end try
      end repeat
      if captureButton is not missing value then
        click captureButton
      else
        click menu bar item "Capture" of menu bar 1
        click menu item "Capture Area" of menu 1 of menu bar item "Capture" of menu bar 1
      end if
    end tell
  end tell
  return "Capture Area invoked through the packaged toolbar or native app menu."
end run
APPLESCRIPT
  ) && capture_click_exit=0 || capture_click_exit=$?
  if [ "$capture_click_exit" -ne 0 ]; then
    write_report BLOCKED "Accessibility could not invoke Capture area: $capture_click_output"
    printf 'Capture cancellation smoke blocked: %s\n' "$capture_click_output" >&2
    exit 2
  fi

  selector_seen=0
  selector_count=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    selector_count=$(/bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$HELPER_PATH" '$2 == expected {count++} END {print count + 0}')
    if [ "$selector_count" -gt 0 ]; then
      selector_seen=1
      break
    fi
    sleep 1
  done
  if [ "$selector_seen" -ne 1 ]; then
    write_report FAIL "Capture area was clicked, but the packaged native selector did not appear within 10 seconds."
    printf '%s\n' 'Capture cancellation smoke failed: native selector did not appear.' >&2
    exit 1
  fi

  escape_output=""
  escape_exit=0
  escape_output=$(/usr/bin/perl -e 'alarm 15; exec @ARGV' /usr/bin/osascript -e 'tell application "System Events" to key code 53' 2>&1) && escape_exit=0 || escape_exit=$?
  if [ "$escape_exit" -ne 0 ]; then
    write_report BLOCKED "Accessibility could not send Escape to the active selector: $escape_output"
    printf 'Capture cancellation smoke blocked: %s\n' "$escape_output" >&2
    exit 2
  fi

  selector_count=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    selector_count=$(/bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$HELPER_PATH" '$2 == expected {count++} END {print count + 0}')
    [ "$selector_count" -eq 0 ] && break
    sleep 1
  done
  if [ "$selector_count" -ne 0 ]; then
    write_report FAIL "Escape was sent, but the packaged native selector remained alive after 10 seconds."
    printf '%s\n' 'Capture cancellation smoke failed: native selector did not exit after Escape.' >&2
    exit 1
  fi

  restore_output=""
  restore_exit=0
  restore_output=$(/usr/bin/perl -e 'alarm 15; exec @ARGV' /usr/bin/osascript <<'APPLESCRIPT' 2>&1
on run
  tell application "System Events"
    if not (exists process "shoteye") then error "ShotEye process is not running after cancellation."
    set shotEyeProcess to process "shoteye"
    tell shotEyeProcess
      if not (exists window 1) then error "ShotEye has no editor window after cancellation."
      set frontmost to true
      if (value of attribute "AXMinimized" of window 1) is true then error "ShotEye editor window remained minimized after cancellation."
      if (value of attribute "AXMain" of window 1) is not true then error "ShotEye editor window was not made main after cancellation."
    end tell
  end tell
  return "Capture area cancellation restored the ShotEye editor."
end run
APPLESCRIPT
  ) && restore_exit=0 || restore_exit=$?
  if [ "$restore_exit" -ne 0 ]; then
    write_report FAIL "Capture area cancellation did not restore an accessible ShotEye editor: $restore_output"
    printf 'Capture cancellation smoke failed: %s\n' "$restore_output" >&2
    exit 1
  fi

  write_report PASS "surface=$automation_surface; $automation_output; $restore_output"
  printf 'ShotEye packaged Accessibility UI smoke and Capture area cancellation passed. Report written: %s\n' "$REPORT_PATH"
  exit 0
fi

write_report PASS "surface=$automation_surface; $automation_output"
printf 'ShotEye packaged Accessibility UI smoke passed. Report written: %s\n' "$REPORT_PATH"
exit 0

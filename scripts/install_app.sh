#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s BUILT_APP\n' "$0" >&2
  exit 2
fi

SOURCE_APP=$1
DEST_APP=/Applications/ShotEye.app

case "$(uname -m)" in
  arm64) EXPECTED_MACHO="arm64" ;;
  x86_64) EXPECTED_MACHO="x86_64" ;;
  *)
    printf 'Unsupported macOS architecture: %s\n' "$(uname -m)" >&2
    exit 1
    ;;
esac

if [ ! -d "$SOURCE_APP" ]; then
  printf 'Built ShotEye app not found: %s\n' "$SOURCE_APP" >&2
  exit 1
fi

source_executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$SOURCE_APP/Contents/Info.plist")
source_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SOURCE_APP/Contents/Info.plist")
if [ "$source_executable" != "shoteye" ] || [ "$source_identifier" != "com.moltbagus.shoteye.tauri" ]; then
  printf 'Source is not the packaged ShotEye bundle: %s (%s)\n' "$source_executable" "$source_identifier" >&2
  exit 1
fi
if [ ! -x "$SOURCE_APP/Contents/MacOS/shoteye" ] || [ ! -x "$SOURCE_APP/Contents/Resources/native/ShotEyeSelector" ]; then
  printf 'Source ShotEye bundle is missing an executable or native selector: %s\n' "$SOURCE_APP" >&2
  exit 1
fi
if ! /usr/bin/codesign --verify --deep --strict "$SOURCE_APP"; then
  printf 'Source ShotEye bundle failed strict code-signature validation: %s\n' "$SOURCE_APP" >&2
  exit 1
fi
if ! /usr/bin/file "$SOURCE_APP/Contents/MacOS/shoteye" | /usr/bin/grep -q "Mach-O.*$EXPECTED_MACHO"; then
  printf 'Source ShotEye executable has the wrong architecture: %s\n' "$SOURCE_APP" >&2
  exit 1
fi
if ! /usr/bin/file "$SOURCE_APP/Contents/Resources/native/ShotEyeSelector" | /usr/bin/grep -q "Mach-O.*$EXPECTED_MACHO"; then
  printf 'Source ShotEye selector has the wrong architecture: %s\n' "$SOURCE_APP" >&2
  exit 1
fi

running_pids() {
  /bin/ps -axo pid=,args= | /usr/bin/awk -v expected="$DEST_APP/Contents/MacOS/shoteye" '$2 == expected { print $1 }'
}

stop_running_app() {
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
    printf 'Could not stop the existing ShotEye process; leaving the installed bundle untouched.\n' >&2
    exit 1
  fi
}

# Stage the copy away from /Applications first. If staging or validation fails,
# the currently installed application is left untouched.
STAGING_ROOT=$(mktemp -d -t shoteye-install)
STAGING_APP="$STAGING_ROOT/ShotEye.app"
ditto "$SOURCE_APP" "$STAGING_APP"

# Keep one canonical launch target. Moving the prior bundle is recoverable and
# avoids Launch Services or TCC following a stale copy of the application. The
# backup is kept in a unique temporary directory instead of assuming a specific
# home-directory Trash layout.
if [ -d "$DEST_APP" ] || [ -L "$DEST_APP" ]; then
  stop_running_app
  BACKUP_ROOT=$(mktemp -d -t shoteye-previous)
  BACKUP_APP="$BACKUP_ROOT/ShotEye.app"
  mv "$DEST_APP" "$BACKUP_APP"
  printf 'Moved previous ShotEye bundle to %s\n' "$BACKUP_APP"
fi

if ! mv "$STAGING_APP" "$DEST_APP"; then
  if [ -n "${BACKUP_APP:-}" ] && [ ! -e "$DEST_APP" ]; then
    mv "$BACKUP_APP" "$DEST_APP" || true
  fi
  printf 'Could not install ShotEye at %s; the previous bundle was restored when possible. Staged copy: %s\n' "$DEST_APP" "$STAGING_ROOT" >&2
  exit 1
fi
rmdir "$STAGING_ROOT"
printf 'Installed ShotEye bundle at %s\n' "$DEST_APP"

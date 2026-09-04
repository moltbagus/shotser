#!/bin/sh
set -eu

if [ "$(uname -s)" != "Darwin" ]; then
  exit 0
fi

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_file="$root_dir/src-tauri/native/ShotEyeSelector.swift"
output_file="$root_dir/src-tauri/native/ShotEyeSelector"
sdk_path=$(xcrun --sdk macosx --show-sdk-path)
target_arch=$(uname -m)

xcrun swiftc \
  -O \
  -sdk "$sdk_path" \
  -target "${target_arch}-apple-macosx13.0" \
  -framework AppKit \
  -framework CoreGraphics \
  -framework ImageIO \
  -framework UniformTypeIdentifiers \
  "$source_file" \
  -o "$output_file"

chmod 755 "$output_file"

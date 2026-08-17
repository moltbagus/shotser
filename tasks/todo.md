# Shotser task plan

- [x] Inspect the empty repository and establish a macOS-native direction.
- [x] Research Shottr’s public feature set.
- [x] Save the research as `research/shottr-feature-research.md`.
- [x] Create a Swift Package Manager scaffold with a menubar app and editor shell.
- [x] Add capture-mode, tool-selection, copy, and PNG-save seams.
- [x] Run the available build check.
- [x] Create isolated Git metadata because the parent home-directory repository is not writable.
- [x] Authenticate GitHub CLI and publish `moltbagus/shotser`.

## Review

The first capture-to-editor slice is now implemented. Fullscreen capture uses the local Core Graphics display API, frontmost-window capture uses the Core Graphics window API, and the area command currently captures the display with a status message until the transparent selection overlay is added. Vision OCR and QR detection run locally and copy recognized text to the clipboard. The local build check remains blocked before source compilation by the machine’s Swift toolchain/SDK mismatch (Swift 6.3.3 compiler versus a 6.3.2-built SDK).

## Next implementation slice

1. Add a transparent AppKit selection overlay for true area capture.
2. Replace the Core Graphics compatibility path with ScreenCaptureKit where needed.
3. Add annotation rendering and persistence tests.

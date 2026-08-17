# Shotser task plan

- [x] Inspect the empty repository and establish a macOS-native direction.
- [x] Research Shottr’s public feature set.
- [x] Save the research as `research/shottr-feature-research.md`.
- [x] Create a Swift Package Manager scaffold with a menubar app and editor shell.
- [x] Add capture-mode, tool-selection, copy, and PNG-save seams.
- [x] Run the available build check.

## Review

The scaffold is intentionally pre-capture: the UI and model compile path are represented in source, while ScreenCaptureKit capture and Vision processing remain the next implementation slice. The local build check is blocked by the machine’s Swift toolchain/SDK mismatch (Swift 6.3.3 compiler versus a 6.3.2-built SDK), not by a reported source diagnostic.

## Next implementation slice

1. Add ScreenCaptureKit permission handling and fullscreen/window capture.
2. Add a transparent AppKit selection overlay for area capture.
3. Feed captured `CGImage` values into the editor model.
4. Add Vision OCR/QR actions and persistence tests.

# Shotser

Shotser is a native macOS screenshot and pixel-inspection tool inspired by the workflow of Shottr.

## Current scaffold

- Swift Package Manager macOS executable target.
- Menubar utility shell.
- Capture-mode commands for area, window, and fullscreen capture.
- Editor shell with tool selection, copy, and PNG save actions.
- Clear integration seam for ScreenCaptureKit capture and Vision-based OCR/QR.

## Run

```sh
swift run Shotser
```

The current capture commands open the editor but intentionally do not request Screen Recording permission yet. See [research/shottr-feature-research.md](research/shottr-feature-research.md) for the feature inventory and MVP order.

# Shotser

Shotser is a native macOS screenshot and pixel-inspection tool inspired by the workflow of Shottr.

## Current scaffold

- Swift Package Manager macOS executable target.
- Menubar utility shell.
- Capture-mode commands for area, window, and fullscreen capture.
- Editor shell with tool selection, copy, and PNG save actions.
- Fullscreen, frontmost-window, and drag-selected area capture using local macOS APIs.
- Local Vision OCR and QR detection with clipboard output.
- Permission, empty-state, cancellation, save-success, and save-error feedback.
- Rectangle and arrow annotations included in copied/saved output.
- Open image, clipboard import, and repeat-capture workflows.
- Keyboard shortcuts for the main capture/edit actions.
- Configurable global area-capture shortcut (defaults to `⌘⇧2`) with a Settings recorder.
- Area result actions exposed as Copy and Save icons in the editor toolbar.
- Dark rounded editor toolbar modeled on the supplied Shottr-style reference, with traffic-light controls, grouped tools, color, image-size, and zoom readouts.

## Run

```sh
swift run Shotser
```

## Package a downloadable Apple Silicon build

```sh
./scripts/package_app.sh
```

This creates `dist/Shotser-macOS-arm64.zip`. The archive strips macOS resource-fork metadata so the ad-hoc signature remains valid after extraction. The app is signed for local use; macOS may require the user to approve it in Privacy & Security because it is not notarized.

Screen Recording permission is required by macOS for capture. See [research/shottr-feature-research.md](research/shottr-feature-research.md) for the feature inventory and MVP order.

Opening the extracted app now shows the editor window. The menubar icon remains available for global shortcut capture and repeat workflows.

For local development, use `./script/build_and_run.sh`. It builds a real foreground `.app` bundle, launches it, and supports `--verify` for a process smoke check.

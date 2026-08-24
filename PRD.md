# Shotser PRD v0.3

## Product

Shotser is a native macOS screenshot utility for capturing an area, window, or display and immediately copying, saving, and annotating the result.

## Current outcome

The foreground editor opens as an active macOS application, accepts toolbar input, and exposes a repeatable capture-to-copy/save workflow.

## Current scope

- Area capture with multi-monitor pointer selection.
- Window and fullscreen capture.
- Rectangle and arrow annotations.
- Open image and clipboard import.
- Repeat last capture.
- Configurable global area shortcut.
- Copy/save toolbar actions and OCR/QR workflow.

## Next backlog

- Add a native AppKit interaction regression harness.
- Add undo/redo and crop/reset.
- Add pinning and drag-out export.
- Improve ScreenCaptureKit compatibility and permissions guidance.

## Definition of done

The app launches as one active instance, toolbar actions receive clicks, capture permissions are handled, and the arm64 package opens from a fresh extraction.

## Latest evaluation

Fresh ZIP extraction now launches with `NSRunningApplication.isActive == true` after repeated launch activation timing guards.

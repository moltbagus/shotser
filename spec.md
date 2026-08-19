# Shotser Specification v0.3

## Architecture

- SwiftPM executable targeting macOS 13+.
- SwiftUI owns editor state and toolbar actions.
- AppKit owns activation, capture overlays, panels, and the editor window.
- Core Graphics captures displays/windows; Vision handles OCR and QR detection.

## Interaction contract

1. Launching Shotser activates the application and brings `Shotser Editor` forward.
2. The editor window must be key and must not ignore mouse events.
3. Every toolbar control has an action or a visible status response.
4. A capture overlay must be disabled and closed before the editor is shown.
5. Duplicate launches must not create competing instances.

## Verification contract

- Release build succeeds.
- Fresh extracted app passes `codesign --verify --deep --strict`.
- `NSRunningApplication` reports Shotser active after launch.
- Exactly one Shotser process remains after a normal launch.

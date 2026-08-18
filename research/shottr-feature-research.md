# Shottr feature research

Research date: 2026-08-17  
Primary source: [Shottr](https://shottr.cc/)

## Product direction

Shottr is a small, fast, native macOS screenshot utility aimed at designers, frontend engineers, and mobile developers. The product emphasizes a short path from capture to understanding or sharing a screenshot: capture, inspect, annotate, transform, copy/save, and optionally upload.

## Publicly documented feature inventory

### Capture

- Area capture.
- Active-window capture.
- Fullscreen capture.
- Capture any window.
- Scrolling screenshots for long pages or conversations.
- Delayed screenshots.
- Repeat the previously selected area.
- Open PNG/JPEG files and clipboard images in the editor.
- Drag and drop image files onto the editor.
- Configurable global hotkeys.
- Keyboard shortcuts for repeat capture, open image, clipboard import, OCR, copy, and save.
- Configurable global area-capture shortcut with a default `⌘⇧2` binding.
- Preview thumbnail or editor after capture.

### Editing and composition

- Crop and reset crop.
- Resize screenshots.
- Combine multiple captures on one canvas.
- Expandable canvas and side-by-side screenshots.
- Paste image overlays with adjustable transparency.
- Before/after two-frame animation/GIF workflow.
- Background/backdrop tool with gradients, shadows, rounded corners, wallpaper, or solid background.
- Retina-aware sizing and optional downscaling.
- Undo/redo.

### Annotation and redaction

- Text labels.
- Arrows, including narrow, curved, and bendable arrows.
- Rectangles and ovals with fill and opacity controls.
- Freehand drawing.
- Highlighter.
- Spotlight.
- Step counter.
- Guides.
- Pixelation.
- Blur and erase, including text-only modes.
- Object removal.
- Custom annotation colors, sizes, line styles, and pixelation levels.
- Duplicate drawings with Option-drag.

### Inspection tools

- OCR/text recognition with clipboard output.
- QR code recognition through text recognition.
- Screen ruler and distance measurement.
- Magnifier/zoom callout.
- Pixel color picker.
- Copy text color and average color.
- Color formats including HEX and newer OKLCH/APCA support.
- Zoom and pan controls with keyboard shortcuts.
- Logical-pixel and physical-retina-pixel measurement modes.

### Workflow and sharing

- Copy and save to clipboard/folder.
- Auto-copy and auto-save preferences.
- Dedicated screenshot folder.
- Pin screenshots as borderless always-on-top floating windows.
- Drag screenshots into other applications.
- Upload and copy a link through an activated uploader.
- S3-compatible upload support, including third-party S3 services.
- Menubar utility with quick confirmations.
- Preferences for hotkeys, notifications, telemetry, default zoom, window behavior, and capture appearance.
- URL schemes and integrations for Raycast and Alfred.

## Suggested Shotser MVP

The first scaffold should prove the native capture-to-editor loop before implementing every advanced feature:

1. Menubar app shell with a capture menu.
2. Area, window, and fullscreen capture using ScreenCaptureKit.
3. Editor canvas with crop, zoom, pan, and save/copy actions.
4. Basic markup: arrow, rectangle, text, freehand, highlight, pixelate.
5. OCR action using Vision and QR recognition where available.
6. Pin current image as an always-on-top utility window.
7. A feature-oriented protocol boundary so scrolling capture, backdrops, S3 upload, and advanced inspection tools can be added without rewriting capture state.

## Shotser implemented slice

- Multi-monitor-aware area capture starts on the display under the pointer.
- Rectangle and arrow annotations render over the editor image and are included in copy/save output.
- Open PNG/JPEG/TIFF files and import image data from the clipboard.
- Repeat the last fullscreen, window, or area capture.
- Keyboard shortcuts: Cmd+Shift+R repeat, Cmd+O open image, Cmd+Shift+V clipboard image, Cmd+Shift+T OCR/QR, Cmd+C copy, Cmd+S save.
- Global area capture shortcut defaults to `⌘⇧2` and can be changed in Shotser Settings.

## Apple platform notes

- Target macOS first; use SwiftUI for app chrome and AppKit/ScreenCaptureKit integration where system APIs require it.
- Screen Recording permission is required for screen/window capture.
- Accessibility permission may be needed for advanced scrolling capture or synthetic scrolling.
- Vision provides a natural local-first path for OCR and barcode detection.
- Keep capture and image processing local by default; make uploads explicit and configurable.

## Scope boundary

This document records publicly visible product capabilities and a proposed implementation order. It is not a copy of Shottr’s source code, assets, branding, or proprietary implementation.

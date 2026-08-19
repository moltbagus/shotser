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

The first capture-to-editor slice is now implemented. Fullscreen, frontmost-window, and drag-selected area capture use local Core Graphics APIs. Vision OCR and QR detection run locally and copy recognized text to the clipboard. The local build check remains blocked before source compilation by the machine’s Swift toolchain/SDK mismatch (Swift 6.3.3 compiler versus a 6.3.2-built SDK).

## Next implementation slice

1. Replace the Core Graphics compatibility path with ScreenCaptureKit where needed.
2. Add annotation rendering and persistence tests.
3. Add open-file, clipboard-import, and repeat-capture workflows.

## Handbook shipping review

- [x] Thin capture/edit loop exists locally.
- [x] Empty, cancellation, permission, save-success, and save-error states are represented.
- [x] Apple Silicon packaging script and app metadata added.
- [ ] Local release build and downloadable ZIP: blocked by the installed Swift 6.3.3 compiler versus Swift 6.3.2-built macOS SDK.
- [x] Independent smoke run completed; visual UI assertions remain blocked by macOS permissions.

## Verification results

- Release build produced an arm64 Mach-O executable.
- Ad-hoc code signature verified for `dist/Shotser.app`.
- ZIP integrity check passed for `dist/Shotser-macOS-arm64.zip`.
- Independent smoke run launched the app successfully and confirmed the process remained running.
- Visual menubar/editor confirmation was blocked because macOS denied Assistive Access and display capture to the test runner. Grant Screen Recording and Accessibility permissions to the terminal/Codex host before repeating the UI check.
- Capture overlay is hidden before area pixels are read; window capture now selects the frontmost external Window Server entry.

## Next product slice review

- [x] Multi-monitor-aware area capture using the display under the pointer.
- [x] Rectangle and arrow annotations with composited Copy/Save output.
- [x] Open PNG/JPEG/TIFF files and import clipboard images.
- [x] Repeat fullscreen, window, and area captures.
- [x] Keyboard shortcuts documented and wired for repeat, open, clipboard import, OCR, copy, and save.
- [x] Release build and arm64 ZIP regenerated successfully.
- [x] Configurable global area-capture shortcut added; default is `⌘⇧2`.
- [x] Area result Copy and Save icon actions added to the editor toolbar.
- [x] Reworked the editor toolbar to match the supplied dark top-fold reference: traffic lights, grouped tool icons, color, image size, and zoom readouts.
- [x] Fixed ZIP packaging so extracted bundles retain a valid code signature by removing AppleDouble/resource-fork metadata.
- [x] Fixed launch UX so opening the extracted app shows the Shotser Editor window instead of only starting a hidden menubar process.
- [x] Fixed inactive/unresponsive window behavior by using regular app activation and explicit key-window configuration.
- [x] Added `script/build_and_run.sh` and the Codex Run action for repeatable foreground app launches.

## Debug review — 2026-08-18

- Observed: the downloaded app could fail to open after extraction, and the older build could start only as a menubar process with no reliably active editor window.
- Root causes: ZIP creation preserved AppleDouble `._*` metadata that broke deep signature validation; the app was configured as a UI-element/menu-bar app and did not consistently activate its editor window.
- Fixes: package with metadata/resource-fork suppression; remove `LSUIElement`; activate as a regular app; bring the editor forward as key; explicitly enable standard window controls and mouse interaction.
- Verification: release build succeeded; extracted ZIP had no AppleDouble files; `codesign --verify --deep --strict` passed; `open -n` launched the extracted app; process remained alive; screen capture preflight returned true; recent logs contained no Shotser crash.
- Remaining user setup: global shortcuts require macOS Accessibility/Input Monitoring permission for the installed app. Screen capture permission is already available on this machine.

## Sprint S1-editor-input — 2026-08-18

- [x] Audit AppKit selection overlay as a possible full-screen click interceptor.
- [x] Ensure the overlay disables mouse events and closes before the editor is shown.
- [x] Make toolbar tool selection visibly update the editor status.
- [x] Make empty-state Save/Copy actions report what prerequisite is missing.
- [x] Rebuild, package, and verify the arm64 app signature.

Result: local release build and strict signature verification passed; one Shotser process is running from `dist/Shotser.app`.

## Follow-up root-cause verification — 2026-08-19

- Observed: editor window was visible, but `NSRunningApplication` reported Shotser as `active=false`.
- Cause: activation was attempted only from the manually-created editor window path and could occur before the app finished launching.
- Fix: added an `NSApplicationDelegate` launch activation path and repeated activation after the editor window mounts.
- Verification: rebuilt app reports `active=true` while the editor window is on-screen; release package and strict code-signature verification pass.

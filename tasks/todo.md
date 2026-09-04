# ShotEye task plan

- [x] Inspect the empty repository and establish a macOS-native direction.
- [x] Research Shottr’s public feature set.
- [x] Save the research as `research/shottr-feature-research.md`.
- [x] Create a Swift Package Manager scaffold with a menubar app and editor shell.
- [x] Add capture-mode, tool-selection, copy, and PNG-save seams.
- [x] Run the available build check.
- [x] Create isolated Git metadata because the parent home-directory repository is not writable.
- [x] Authenticate GitHub CLI and publish `moltbagus/shotser`.
- [x] Add bounded direct Accessibility attachment and complete AX hierarchy traversal (S142 / U1).
- [x] Add reversible shortcut fixture and cleanup probe (S142 / U2).
- [ ] Prove packaged conflict and default reset through an exclusive registration boundary (S142 / U3; blocked on current macOS Carbon behavior).
- [x] Record explicit PASS/BLOCKED evidence and update operational contracts (S142 / U4).
- [x] Harden shortcut registration transaction semantics with focused Rust coverage (S143).
- [x] Bound packaged Accessibility automation and verify Capture Area cancellation recovery (S146).
- [x] Verify installed primary-display toolbar capture through HID selection and Copy PNG output (S147).
- [x] Re-run opt-in Capture Area cancellation with bounded execution; S144's observation hang was resolved and S146 produced a passing packaged result.

## Review

### S142 stable Accessibility shortcut-conflict review

- Direct AX packaged smoke passed against the canonical installed app; the report records `surface=direct-ax`.
- The fixture reserved and released its chord successfully, but a second fixture could also reserve it. The acceptance harness therefore returned `BLOCKED` and made no false product-conflict claim.
- Focused shell syntax and Swift compilation passed. No commit or push was performed.

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

## Sprint S123-native-operation-ux — 2026-08-30

- [x] Add a React-visible phase for capture/import/permission/Copy/Save/Drag operations.
- [x] Disable competing native actions while an operation is pending and release the lane in every terminal path.
- [x] Keep annotation tools usable during the Save destination dialog, then prepare the latest revision after destination selection.
- [x] Add deferred App coverage for Copy and Drag progress/recovery and Save-dialog editability.
- [x] Pass focused App 30/30, full frontend 101/101, build, Rust 45/45, check, Clippy, package/install, runtime, installed, DMG, shell, and release-order verification.
- [ ] Complete physical desktop acceptance and public Developer ID/notarization gates.

### Review

S123 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. An independent read-only review was requested; its result is not a substitute for the focused tests or packaged verification.

## Sprint S124-shortcut-conflict-recovery — 2026-08-30

- [x] Add explicit shortcut registration state and a visible settings/reset control.
- [x] Serialize explicit shortcut replacement and gate capture/export actions while registration is pending.
- [x] Preserve the last active shortcut when native registration rejects a replacement.
- [x] Format native shortcut-registration errors in macOS notation.
- [x] Pass focused conflict/recovery coverage, full frontend 103/103, build, Rust 45/45, check, Clippy, package/install, runtime, installed, DMG, shell, and release-order verification.
- [ ] Complete physical desktop acceptance and public Developer ID/notarization gates.

### Review

S124 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S125-canonical-launch-single-instance — 2026-08-30

- [x] Replace supported build/run and installed verification `open -n` launches with `open -a` against `/Applications/ShotEye.app`.
- [x] Add a focused canonical-launch contract test covering the supported runner, verifier, UI smoke harness, and architecture-specific bundle path.
- [x] Archive the stale unqualified generated target bundle recoverably outside the repository build tree.
- [x] Harden `scripts/package_app.sh` to archive stale unqualified bundles automatically and refuse to move a live competing executable.
- [x] Refresh the packaged arm64 app/DMG and record S125 runtime, installed, and mounted-DMG reports; canonical DMG SHA-256 is `a61e7616f05f3e617b0a8e76c999773cf610b954c98c4221778a3fee879fb260`.
- [ ] Complete physical desktop acceptance and public Developer ID/notarization gates.

### Review

S125 implementation is bounded to launch identity and single-instance safety. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S126-package-time-stale-bundle-hardening — 2026-08-30

- [x] Archive stale unqualified generated ShotEye bundles from `scripts/package_app.sh` before architecture-specific packaging.
- [x] Fail closed instead of moving a stale bundle when its executable is currently running.
- [x] Fail installed and mounted-DMG verification closed if the unqualified generated bundle reappears.
- [x] Extend the canonical launch regression and pass package, install, runtime, installed, mounted-DMG, helper, strict-signature, and parity verification.
- [ ] Complete physical desktop acceptance and public Developer ID/notarization gates.

### Review

S126 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S127-mounted-dmg-launch-provenance — 2026-08-30

- [x] Stop only the exact installed ShotEye test process before launching a same-identifier mounted DMG payload.
- [x] Canonicalize macOS `/var` and `/private/var` executable paths for process checks and cleanup.
- [x] Clean up the mounted payload process before DMG detach and record a non-empty launch report.
- [ ] Complete physical desktop acceptance and public Developer ID/notarization gates.

### Review

S127 mounted-DMG launch provenance is verified locally. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S128-capture-orientation-and-toolbar-sizing — 2026-08-30

- [x] Reproduce the mirrored/rotated preview symptom from the native compositor contract and confirm the current helper output self-test fails with the corrected visual expectation.
- [x] Remove the extra compositor y-axis reflection and harden color assertions against `UInt8` overflow.
- [x] Reduce bundled toolbar SVG glyphs to 16px without changing button hit targets or action behavior.
- [x] Run frontend, Rust, native helper, package, install, and canonical DMG verification after the source fix and record fresh S128 reports under `artifacts/tauri-e2e/`; canonical Apple Silicon DMG SHA-256 is `5e9c6d89c49f1698fdef176dac65fc3bc02be59c95aad3669c0f7c08dba52cd8`.
- [ ] Complete physical pointer-selection, toolbar, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current smoke is blocked by `-2700` (`Missing accessible button: Open image`).
- [ ] Obtain Developer ID signing and notarization credentials for public release verification.

### Review

S128 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. Physical desktop interaction remains an external acceptance gate because the current Accessibility smoke harness cannot access the expected control tree.

## Sprint S129-packaged-capture-acceptance-and-ax-harness — 2026-08-30

- [x] Reproduce the UI smoke failure and confirm the installed WebView exposes native menus but not DOM button roles to System Events.
- [x] Update the smoke harness to use the native Tools/Capture menus when DOM button Accessibility is unavailable, while recording the limitation explicitly.
- [x] Pass the exact installed Capture Area → selector observation → Escape → selector exit → editor restoration flow.
- [x] Pass a real HID area drag through the installed selector and validate ShotEye's Copy Capture clipboard output as a non-empty `600×500` PNG.
- [ ] Complete physical toolbar pointer, global shortcut, Finder-drop, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S129 is locally verified against the installed package. The harness no longer reports a false missing-button failure; it records the WebView AX limitation and keeps native-menu/HID capture evidence separate from physical toolbar claims. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S130-nested-toolbar-accessibility-harness — 2026-08-30

- [x] Confirm toolbar controls are nested below the WebView `AXWebArea`, while Pin is exposed as an `AXCheckBox`.
- [x] Update the installed-package smoke harness to traverse nested controls instead of checking only direct window buttons.
- [x] Pass 25 editor-control checks, six menu checks, and reversible packaged toolbar clicks for Rectangle and Select.
- [x] Record `artifacts/tauri-e2e/s130-physical-ui-toolbar-smoke.txt`.
- [ ] Complete global shortcut, Finder-drop, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S130 is locally verified against the installed package. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S131-toolbar-capture-acceptance — 2026-08-30

- [x] Click the actual installed ShotEye Capture area toolbar control through the nested Accessibility tree.
- [x] Drive a real HID selection through the bundled native selector and verify normal selector exit/editor restoration.
- [x] Validate ShotEye's own Copy Capture path as a non-empty `600×500` PNG and record the result.
- [x] Record `artifacts/tauri-e2e/s131-toolbar-capture-success.txt` and `s131-toolbar-capture-success.png`.
- [ ] Complete global shortcut, Finder-drop, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S131 toolbar capture acceptance is locally verified against `/Applications/ShotEye.app`; the evidence is intentionally scoped to one-display toolbar-to-clipboard behavior. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S132-global-shortcut-acceptance — 2026-08-30

- [x] Trigger the installed default `⌘⇧Y` shortcut while Finder is frontmost and verify selector cancellation/restoration.
- [x] Record custom `⌘⇧U` through the installed toolbar and trigger it while Finder is frontmost.
- [x] Reset to default and verify `⌘⇧Y` still launches the selector.
- [x] Record `artifacts/tauri-e2e/s132-shortcut-acceptance.txt`.
- [ ] Verify conflict feedback with an occupied shortcut, alternate keyboard layouts, Finder-drop, secondary-display behavior, Developer ID, Gatekeeper, and notarization.

### Review

S132 global shortcut routing and reset recovery are locally verified against `/Applications/ShotEye.app`. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.
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

## Sprint S2-tauri-diagnostic — 2026-08-25

- [x] Build a production Tauri macOS bundle with React/WKWebView and a Rust command bridge.
- [x] Verify the packaged app has a distinct bundle identifier from the legacy Swift app.
- [x] Verify Copy, Save, Select, Arrow, Rectangle, Text, Draw, and Capture area all invoke Rust from the visible toolbar.
- [x] Configure Tauri ad-hoc macOS bundle signing and verify the rebuilt app with `codesign --verify --deep --strict`.
- [x] Save a verified interaction screenshot under `artifacts/tauri-e2e/`.

### Review

The Tauri production bundle loaded cleanly and all eight toolbar actions passed direct packaged-app interaction testing. No blank screen, asset-resolution, CSP, or Rust IPC bug reproduced. Tauri is configured for valid local ad-hoc signing; public distribution still requires a Developer ID certificate and notarization. The current controls are diagnostic only; the next vertical slice is a native macOS capture adapter that returns image data for Copy and Save.

## Sprint S3-tauri-capture — 2026-08-25

- [x] Add a Rust `screencapture` command for interactive macOS area capture.
- [x] Preview successful capture bytes in the React editor.
- [x] Separate clipboard copy from capture and report empty-state errors.
- [x] Verify cancelled selection returns a visible `Capture cancelled.` status without freezing the app.
- [x] Verify macOS Screen Recording smoke capture produces a valid PNG.
- [x] Add native Save panel integration and verify its cancellation path returns to the editor.
- [ ] Complete an independent successful drag-selection regression.

### Review

The capture seam is implemented and cancellation/error behavior is verified. The current automated desktop runner caused the interactive selector to cancel before a drag could be delivered; this is a test-harness limitation, not evidence that successful selection is complete. Save dialog integration and successful physical selection remain open acceptance items.

## Debug follow-up — 2026-08-27

- [x] Remove stale Shotser Tauri dev/Vite/debug processes left by interrupted runs.
- [x] Relaunch exactly one packaged Tauri instance.
- [x] Reconfirm packaged UI loads and toolbar accessibility tree is present.

### Review

The repeated-instance symptom was reproduced at the process level: three stale development/debug processes were present. They were terminated by exact project path, leaving one packaged app process. The packaged app then loaded with all controls discoverable.

## Sprint S4-tauri-capture-hardening — 2026-08-28

- [x] Remove stale capture output before every native selection.
- [x] Validate PNG signature before preview, Copy, or Save.
- [x] Reject empty-state Copy/Save before native operations.
- [x] Disable editor actions while the native selector is active.

### Review

Capture/export now has truthful state transitions: cancellation or malformed output cannot surface a previous image, and Copy/Save require a current validated preview. Builds, Rust checks, release packaging, strict signature verification, and diff checks pass. The remaining acceptance gap is an independent completed physical drag on the desktop selector.

## Sprint S5-tauri-hidden-capture — 2026-08-29

- [x] Hide the Tauri editor before interactive area capture.
- [x] Restore and focus the editor after success, cancellation, permission failure, or IPC failure.
- [x] Preserve capture busy-state protection against repeated clicks.
- [x] Update the native capture lifecycle contract.

### Review

The editor now leaves the desktop unobstructed during area selection and is restored in a `finally` path. Existing Rust capture, stale-file cleanup, PNG validation, Copy, and Save behavior remain unchanged.

## Sprint S6-tauri-lifecycle — 2026-08-29

- [x] Add a packaged single-instance guard that restores and focuses the existing editor.
- [x] Add the default global area-capture shortcut, `⌘⇧Y`.
- [x] Route shortcut presses through the existing frontend hide/capture/restore flow.

### Review

Two launch requests leave exactly one installed Shotser Tauri process. Shortcut registration is Rust-owned and emits a pressed-only event, preserving the existing capture busy-state guard. A configurable shortcut UI and canonical Rust image state remain subsequent slices.

## Sprint S7-tauri-canonical-capture — 2026-08-29

- [x] Add a Rust-owned latest capture record with PNG bytes and dimensions.
- [x] Store only validated successful captures in that record.
- [x] Make Copy and Save read from the record instead of the shared temp file.
- [x] Keep temp files as implementation details only for macOS clipboard scripting.
- [x] Run focused frontend, Rust, package, signature, and launch verification.

### Review

Frontend TypeScript build, Rust `cargo check`, and Rust unit tests passed. The signed macOS `.app` and DMG bundles built, the app installed to `/Applications/Shotser Tauri.app`, strict code-signature verification passed, launch succeeded, and the single-instance guard still held after a second launch. `cargo fmt --check` is blocked by the missing local `rustfmt` component.

## Sprint S8-tauri-annotation-export — 2026-08-29

- [x] Define an image-coordinate annotation model for Rectangle, Arrow, Text, and Draw.
- [x] Render annotations as an interactive SVG overlay without mutating the original preview.
- [x] Rasterize the overlay only at Copy/Save and update the Rust-owned canonical export record.
- [x] Add Undo, Clear, Escape cancellation, color, stroke, text, and zoom controls.
- [x] Repair the Tauri window ACL so the editor can restore after hidden capture.
- [x] Run frontend/Rust/package verification and record packaged-app evidence.

### Review

The installed bundle now exposes its toolbar controls to the packaged accessibility harness. The harness clicked Rectangle successfully, then started a native capture. Ending that test selector restored the editor through the frontend `finally` lifecycle with no Tauri ACL error. A successful physical drag-selection and annotated Copy/Save image remain the next evidence targets.

## Sprint S9-tauri-image-import — 2026-08-29

- [x] Define a file/clipboard import contract that normalizes supported image formats to canonical PNG bytes.
- [x] Add Rust file and macOS clipboard import commands.
- [x] Add Open and Paste controls that reset annotations only after a successful new image result.
- [x] Build, package, and verify import behavior in the installed app.

### Review

The installed app opened a JPEG through the native dialog, normalized it to a 1240×1754 PNG preview, copied that image, and imported it back from the macOS clipboard. A physical Rectangle drag added one annotation; after Copy → Paste the rendered rectangle was visibly preserved. Native Save then wrote a valid 1240×1754 RGBA PNG to `artifacts/tauri-e2e/s9-annotated-export.png`.

## Sprint S10-tauri-repeat-capture — 2026-08-29

- [x] Track only the last successful native capture mode in Rust state.
- [x] Add fullscreen and Repeat Last Capture commands behind the existing image model.
- [x] Hide and restore the editor around fullscreen/repeat operations.
- [x] Add an actionable Screen Recording settings route for denied native capture.
- [ ] Package and verify real fullscreen capture and repeat in the installed app.

## Sprint S11-tauri-permission-preflight — 2026-08-29

- [x] Trace repeated macOS Screen & System Audio Recording prompts to the `screencapture` adapter and ad-hoc bundle identity.
- [x] Add a non-prompting Core Graphics preflight gate before native capture.
- [x] Build, package, and verify unavailable access returns in-app status without a repeated system consent prompt.
- [x] Move the one-time native permission request behind the explicit Permissions button.
- [x] Reset and re-enable the current installed build's Screen Recording permission, then verify Full screen and Repeat Last Capture.
- [ ] Obtain Developer ID signing before public-beta distribution.

### Review

Focused Rust regression and `cargo check` passed. The rebuilt `/Applications/Shotser Tauri.app` passed strict signature validation. A packaged-app click on Capture area returned the in-app unavailable-permission status without hiding the editor or opening a macOS consent sheet; evidence: `artifacts/tauri-e2e/s11-permission-preflight.jpg`. After the user-authorized TCC reset/re-enable, Full screen captured a valid 2940×1912 preview and Repeat Last Capture completed through the same packaged lifecycle; evidence: `artifacts/tauri-e2e/s11-fullscreen-repeat.jpg`.

## Sprint S12-release-branding — 2026-08-29

- [x] Remove the user-facing “Tauri diagnostic” title and backend-check button.
- [x] Build, install, and visually verify the clean Shotser editor title.

### Review

The packaged editor now shows `Shotser` as its in-window title, starts with the product-facing `Ready to capture.` status, and has no backend-check control. Visual evidence: `artifacts/tauri-e2e/s12-release-branding.jpg`.

## Sprint S13-shoteye-rename — 2026-08-29

- [x] Rename all user-facing application, toolbar, status, capture, save, window, menu, bundle, and DMG branding to ShotEye.
- [x] Build, install, and verify the ShotEye macOS window and menu name.
- [ ] Re-authorize Screen Recording for the renamed ad-hoc build, then re-run capture acceptance.

### Review

`/Applications/ShotEye.app` is the only current application copy in Applications; the previous Shotser Tauri copy was moved to Trash. The running packaged app exposes `ShotEye` in the macOS window and application menu, as well as the editor title and toolbar. Visual evidence: `artifacts/tauri-e2e/s13-shoteye-rename.jpg`.

### Review

Frontend build, Rust check, and 10 Rust tests pass. The signed DMG and installed app were regenerated. The first real Full screen attempt reached the native command and restored the editor, but macOS denied Screen Recording to the latest ad-hoc binary. The in-app Permissions route is included in the installed bundle; its live check is pending until the locked Mac is unlocked and permission can be re-enabled.

## Sprint S14-shoteye-stable-local-signing — 2026-08-29

- [x] Create a persistent `ShotEye Local Development` code-signing identity in the macOS login keychain.
- [x] Package a Tauri bundle with that identity and inspect its strict code signature.
- [x] Reject the local-identity approach after packaged control testing proved it launches a blank WebKit editor, while the preserved ad-hoc bundle renders normally.
- [x] Restore the known-working ad-hoc package and keep the local identity unused.
- [ ] Obtain and configure an Apple Developer `Developer ID Application` identity, then verify Screen Recording continuity across a rebuild and relaunch.
- [ ] Replace the local identity with a Developer ID certificate before public-beta distribution and notarization.

### Review

`ShotEye Local Development` is a valid local keychain code-signing identity. A fresh Tauri package signed with it passed `codesign --verify --deep --strict` and reported that authority, but the installed package rendered a blank WebKit editor. A preserved ad-hoc control with matching metadata rendered the complete editor and accessibility tree. The certificate-signed app was moved to Trash and the known-working `/Applications/ShotEye.app` was restored and re-verified. No permission-continuity claim is made; a real Developer ID identity is the required next release dependency.

The restored packaged app then completed a focused Full screen regression and returned a valid `2940×1912` preview. Evidence: the live packaged-app accessibility result plus `artifacts/tauri-e2e/s14-ad-hoc-restored.jpg` for the restored interactive editor.

## Sprint S15-multidisplay-area-selector — 2026-08-29

- [x] Make macOS selection mode explicit with `screencapture -i -J selection`.
- [x] Preserve macOS unified display-space behavior by prohibiting main-display (`-m`) and display-target (`-D`) flags for area capture.
- [x] Add a focused Rust regression for the multi-display selector contract.
- [x] Update the editor’s capture guidance to state that selection may cross connected displays.
- [x] Build, package, install, and verify the updated guidance in `/Applications/ShotEye.app`.
- [ ] Complete a physical second-display drag acceptance run on a Mac with a connected secondary display.

### Review

`screencapture` local help confirms `-i` is interactive selection and `-m` restricts capture to the main monitor. The focused Rust regression passed, as did TypeScript/Vite production build and packaged strict signature verification. The latest ad-hoc package displays the multi-display guidance. Its Screen Recording preflight safely reports unavailable access after the binary changed; evidence: `artifacts/tauri-e2e/s15-multidisplay-permission-preflight.jpg`. No capture success is claimed for this build until the exact installed app is re-authorized and a physical secondary-display drag is performed.

## Sprint S16-configurable-capture-shortcut — 2026-08-29

- [x] Preserve the startup default capture shortcut (`CommandOrControl+Shift+Y`) in Rust so capture works before the WebView becomes ready.
- [x] Add a Rust-owned rebind command that registers the requested shortcut before unregistering the old one, retaining the old shortcut on any failure.
- [x] Add a keyboard recorder control that stores only successfully registered shortcuts in local browser storage.
- [x] Add focused shortcut validation regression, Rust command check, frontend TypeScript build, and packaged strict-signature verification.
- [ ] Perform one physical modifier-key recording and global invocation on the exact installed package; the automation harness cannot route modifier chords into a WebView recorder control.

### Review

The packaged app exposes `Record capture shortcut` and reports the current effective shortcut in its accessibility tree. The focused Rust validation test and `cargo check` passed; the TypeScript/Vite production build and arm64 package succeeded. Evidence: `artifacts/tauri-e2e/s16-shortcut-recorder.jpg`. The recorder remains armed when the accessibility harness sends a chord because that harness cannot focus and deliver the physical modifier event to a WebView button; this is recorded as an automation limitation, not a feature pass.

## Sprint S17-permission-recovery-control — 2026-08-29

- [x] Expose the existing Rust Screen Recording settings route in the product toolbar.
- [x] Keep explicit consent and settings navigation separate: `Permissions` requests consent; `Open settings` navigates to the relevant macOS pane.
- [x] Build, package, install, strictly validate, and inspect the new control in the packaged app.

### Review

The TypeScript/Vite production build and arm64 packaging passed. `/Applications/ShotEye.app` passes `codesign --verify --deep --strict` and exposes `Open Screen Recording settings` in the packaged accessibility tree. Evidence: `artifacts/tauri-e2e/s17-permission-recovery-control.jpg`. The control itself was not invoked, so System Settings was not changed by automated verification.

## Sprint S19-crop-reset-regression — 2026-08-29

- [x] Normalize Crop drags into bounded image-space rectangles shared by the SVG guide and canvas export path.
- [x] Add focused frontend coverage for normal, reverse, and edge-clamped crop drags.
- [x] Run the frontend crop regression, production build, Rust command-boundary suite, and arm64 packaging/signature validation.
- [x] Install this exact bundle and complete a physical Open image → Crop → Reset → Copy/Save acceptance run.

### Review

`npm test` passes three crop-geometry regressions; `npm run build` passes; and all 13 Rust tests pass. The newly built app passes `codesign --verify --deep --strict`; the distributable DMG is `tauri-app/src-tauri/target/release/bundle/dmg/ShotEye_0.1.0_aarch64.dmg`. The installed package opened a JPEG (810×1440), cropped it to 454×227, reset to the original, copied the cropped image, and saved a valid RGBA PNG with matching dimensions. Evidence: `artifacts/tauri-e2e/s19-crop-reset-copy-save.jpg` and `artifacts/tauri-e2e/s19-cropped-export.png`.

## Sprint S18-native-titlebar-only — 2026-08-29

- [x] Remove the WebView-rendered imitation traffic lights and duplicate product header.
- [x] Keep macOS's native close, minimize, and zoom controls as the sole window-control authority.
- [x] Build, package, install, strictly validate, and visually inspect the corrected `/Applications/ShotEye.app`.

### Review

The duplicate controls were caused by a stale HTML titlebar within the React editor, beneath the native macOS titlebar. The packaged app now has only the native `close`, `minimize`, and `zoom` accessibility controls; the WebView begins with the ShotEye toolbar. `npm run build`, arm64 Tauri packaging, and `codesign --verify --deep --strict /Applications/ShotEye.app` passed. Evidence: `artifacts/tauri-e2e/s18-native-titlebar-only.jpg` (980×680 JPEG).

## Sprint S20-exact-build-permission-preflight — 2026-08-29

- [x] Install the latest strict-valid arm64 package at `/Applications/ShotEye.app`.
- [x] Verify Capture area preflights TCC and stays in-app when the installed binary has no Screen Recording grant.
- [ ] With operator confirmation, request Screen Recording access for this exact installed package and perform physical Capture area → Copy → Save acceptance.

### Review

The exact installed package reports one actionable unavailable-permission status and does not re-open a consent prompt during Capture area. Evidence: `artifacts/tauri-e2e/s20-exact-build-permission-preflight.jpg` (980×680 JPEG). Granting Screen Recording is a macOS system-security change and awaits action-time operator confirmation. The package is ad-hoc signed; Developer ID signing is still required to preserve the grant across future rebuilt versions.

## Sprint S21-annotation-undo-redo — 2026-08-29

- [x] Add a deterministic annotation-history model for append, Undo, Redo, and Clear transitions.
- [x] Add focused frontend tests for undo/redo order, divergent edits, empty history, and Clear behavior.
- [x] Build, package, install, strictly validate, and exercise the Undo → Redo path in the exact installed app.

### Review

The frontend suite now has seven tests across crop geometry and annotation history; the production build and all 13 Rust tests pass. The installed app opened an image, added a Rectangle, removed it with Undo, then restored it with Redo; button enabled states and annotation count matched each transition. Evidence: `artifacts/tauri-e2e/s21-annotation-undo-redo.jpg` (980×680 JPEG).

## Sprint S22-native-shortcut-display — 2026-08-29

- [x] Render configured global shortcuts in familiar macOS symbol notation instead of global-shortcut registration syntax.
- [x] Format success/status messages with the same notation.
- [x] Add focused formatting regressions and inspect the freshly installed package.

### Review

The frontend suite has 11 tests across crop, annotation history, and shortcut formatting; the production build passed. The installed package displays the default shortcut as `⌘⇧Y` in its toolbar and status line without leaking `CommandOrControl+Shift+Y`. Evidence: `artifacts/tauri-e2e/s22-native-shortcut-display.jpg` (980×680 JPEG).

## Sprint S23-annotation-selection-delete — 2026-08-29

- [x] Add source-image hit testing for rectangles, arrows, freehand paths, and text.
- [x] Make Select choose the topmost annotation under the pointer.
- [x] Add Delete/Backspace removal with a recoverable Undo history entry.
- [x] Add focused hit-test/history regressions and verify the packaged UI.
- [x] Add move and resize handles for selected annotations.

### Review

The frontend suite has 15 tests; production build, Rust tests, and strict arm64 packaging passed. The installed package selected a Rectangle, deleted it, and restored it with Undo; accessibility state showed the expected annotation counts and enabled Undo. Evidence: `artifacts/tauri-e2e/s23-select-delete-undo.jpg` (980×680 JPEG).

## Sprint S24-annotation-move — 2026-08-29

- [x] Add source-image drag-to-move for selected annotations.
- [x] Keep pointer drafts synchronous and derive movement from the original annotation to avoid stale state and double translation.
- [x] Commit one move as one Undo history transition; clicks without movement remain no-ops.
- [x] Build, package, install, strictly validate, and exercise Select → move → Undo in the exact installed app.
- [x] Add resize handles for selected annotations.

### Review

The packaged `/Applications/ShotEye.app` loaded a PNG, added a Rectangle, selected it, moved it by drag, and reported `Moved selected annotation.`; Undo then reported `Undid last annotation.` with one annotation remaining. `npm test` passes 15 tests, `npm run build`, `cargo check`, `cargo test` (13 tests), arm64 Tauri packaging, and `codesign --verify --deep --strict` pass. Evidence: `artifacts/tauri-e2e/s24-annotation-move.jpg` (980×680 JPEG). The bundle remains ad-hoc signed and physical screen capture remains pending exact-binary Screen Recording authorization.

## Sprint S25-local-workspace-rename — 2026-08-29

- [x] Rename the local workspace directory from `shotser` to `shoteye`.
- [x] Rename the former isolated Git metadata directory to `.shoteye-git` and update its absolute `core.worktree`.
- [x] Update local ignore, Codex environment, and plan references to the renamed metadata directory.
- [x] Preserve the existing `main` branch and `moltbagus/shotser` remote.

### Review

The local source repository is now `/Users/colbert1/shoteye`, with Git metadata at `/Users/colbert1/shoteye/.shoteye-git`; the repository remains on `main`, and its remote URL is unchanged by design.

## Sprint S26-annotation-resize — 2026-08-29

- [x] Define rectangle corner and arrow endpoint resize geometry in source-image coordinates.
- [x] Integrate selected-annotation handles with synchronous pointer drafts and shared undo history.
- [x] Add focused rectangle/arrow geometry regressions and run the frontend suite.
- [x] Build, package, install, and verify the resize workflow in the exact `/Applications/ShotEye.app` bundle.
- [ ] Re-authorize Screen Recording for the exact package and complete physical capture acceptance.

### Review

`npm test` passes 17 tests across four files, `npm run build` passes, and `cargo check` passed after clearing stale pre-rename target paths. The installed `/Applications/ShotEye.app` passes `codesign --verify --deep --strict`. In the packaged UI, a rectangle was selected, resized through its bottom-right handle, then restored with Undo; an arrow endpoint was also resized and its status confirmed. Evidence: `artifacts/tauri-e2e/s26-annotation-resize.jpg`, `artifacts/tauri-e2e/s26-annotation-resize-undo.jpg`, and `artifacts/tauri-e2e/s26-arrow-endpoint-resize.jpg` (all 980×680 JPEG).

## Sprint S27-native-appkit-selector — 2026-08-29

- [x] Add a bundled Swift/AppKit selector that spans the connected display union and supports Escape cancellation.
- [x] Composite selected display pixels into a PNG at native display scale.
- [x] Resolve the helper from Tauri's packaged `Contents/Resources/native` path and retain `screencapture` fallback behavior.
- [x] Compile the helper, package the arm64 app, install the exact bundle, and verify strict signing/resource presence.
- [x] Verify the exact installed app launches and Capture area produces one actionable permission status without reopening the consent prompt.
- [ ] Re-authorize Screen Recording for the exact package and complete physical area capture, Copy, Save, and secondary-display acceptance.

### Review

`npm run build:selector`, `cargo check`, `npm run build`, and the 17-test frontend suite pass. Tauri packaging produces an arm64 `ShotEye.app` and DMG; the helper is present at `Contents/Resources/native/ShotEyeSelector`. The installed package launches with the ShotEye UI and its capture permission preflight prevents repeated prompts when the exact ad-hoc binary lacks TCC access. No physical capture success is claimed until Screen Recording is authorized for this installed package.

## Sprint S28-editor-shortcuts — 2026-08-29

- [x] Add a pure editor shortcut mapper for Undo, Redo, Open, Paste, Copy, Save, and Delete.
- [x] Ignore option chords, editable fields, and the active capture-shortcut recorder.
- [x] Add focused shortcut mapping coverage.
- [x] Build, package, install, and verify Cmd+Z / Cmd+Shift+Z in the exact packaged app.
- [ ] Re-authorize Screen Recording for the exact package and complete physical capture acceptance.

### Review

The frontend suite passes 21 tests across five files, the production build passes, and Cargo checks pass. In `/Applications/ShotEye.app`, a rectangle was added, `Cmd+Z` reported `Undid last annotation.` with zero annotations, and `Cmd+Shift+Z` reported `Redid last annotation.` with one annotation. Evidence: `artifacts/tauri-e2e/s28-shortcuts-history.jpg` (980×680 JPEG).

## Sprint S29-capture-reliability-hardening — 2026-08-29

- [x] Add focused Rust regressions for native PNG validation, helper fallback decisions, and cancellation/failure status mapping.
- [x] Make the bundled AppKit selector key-capable and cancel safely on deactivation.
- [x] Order the selector out before capture and correct vertical multi-display composition.
- [x] Preserve the last valid Rust-owned capture across unsuccessful replacement attempts.
- [x] Add native screen-capture usage metadata and align the minimum macOS version with the Swift helper.
- [x] Build, package, install, and verify the exact arm64 ShotEye bundle, helper resource, metadata, and strict signature.
- [ ] With exact-package Screen Recording authorization, complete physical area selection, Copy, Save, and secondary-display acceptance.

### Review

Focused RED-to-GREEN verification passed: 18 Rust tests, 21 frontend tests, TypeScript/Vite production build, Cargo check, and Swift selector compilation. The arm64 Tauri `.app` and DMG built successfully. `/Applications/ShotEye.app` now reports `CFBundleIdentifier=com.moltbagus.shoteye.tauri`, `NSScreenCaptureUsageDescription`, `LSMinimumSystemVersion=13.0`, and passes `codesign --verify --deep --strict`; the installed helper hash matches the packaged helper and one exact ShotEye process is running. A runtime PNG artifact exists at `artifacts/tauri-e2e/s29-shoteye-runtime.png` (2940×1912). Physical capture success remains unproven because the ad-hoc package has no durable Developer ID identity and the current TCC state is unavailable to this process. Accessibility click-level acceptance is also pending because the test daemon retains the deleted `/Users/colbert1/shotser` working directory.

## Sprint S30-window-capture — 2026-08-30

- [x] Add a first-class `capture_window` Rust command using macOS `screencapture -i -J window`.
- [x] Add a Window toolbar action with hide/restore status messaging and capture-lock protection.
- [x] Preserve successful window captures as the Repeat Last Capture mode.
- [x] Add focused native-argument coverage and package/install the exact arm64 app.
- [ ] With exact-package Screen Recording authorization, complete physical window selection and Copy/Save acceptance.

### Review

Focused verification passed: 18 Rust tests, 21 frontend tests, TypeScript/Vite build, Swift helper build, and Tauri arm64 packaging. `/Applications/ShotEye.app` was replaced from the latest package and launches as one process; strict app signature verification passes and the bundled helper hash is `b78886ee93b49b497e2632ae5aa925bb23641abb7dfac6464033ace23dac2df2`. The physical window-selection path remains permission-gated and is not claimed without exact-package Screen Recording evidence.

## Sprint S31-permission-state — 2026-08-30

- [x] Add a Rust `screen_capture_permission_status` command backed by non-prompting Core Graphics preflight.
- [x] Run the permission check on editor startup without requesting consent.
- [x] Surface the real permission state through the existing branded status area and retain explicit Permissions/Open settings actions.
- [x] Add focused status-message coverage and repackage/install the exact arm64 app.
- [ ] With exact-package Screen Recording authorization, verify the startup state reports available and complete physical area/window capture plus Copy/Save.

### Review

Focused verification passed: 19 Rust tests, 21 frontend tests, TypeScript/Vite build, Swift helper build, and Tauri arm64 packaging. `/Applications/ShotEye.app` contains the startup preflight command, matches the built executable byte-for-byte, passes strict signature verification, and runs as one ShotEye process. The current exact-binary permission result remains unavailable to this process; no consent-loop or physical success claim is made.

## Sprint S32-pin-window — 2026-08-30

- [x] Add a Pin/Unpin control backed by Tauri's native `setAlwaysOnTop` window API.
- [x] Add `core:window:allow-set-always-on-top` to the main-window capability.
- [x] Guard rapid toggles and update the visible state only after the native call succeeds.
- [x] Build, package, install, and verify the exact arm64 bundle contains the capability and Pin action.
- [ ] Independently click Pin and verify the installed window remains above another application, then toggle it off.

### Review

Focused frontend tests (21), Cargo check, TypeScript/Vite build, Swift helper build, Tauri arm64 packaging, strict app signature verification, and exact installed-bundle parity passed. The installed app contains the Pin action and `allow-set-always-on-top` capability; physical always-on-top behavior remains pending desktop automation access.

## Sprint S33-private-clipboard-staging — 2026-08-30

- [x] Reuse private per-operation temporary directories for native clipboard Copy staging.
- [x] Reuse the same private staging model for PNG/TIFF clipboard import.
- [x] Preserve cleanup on success, failure, and early return through the RAII guard.
- [x] Add focused macOS private-path coverage and repackage/install the exact arm64 app.
- [ ] Independently verify Copy and Paste against the installed app after exact-package permissions are authorized.

### Review

Focused verification passed: 20 Rust tests, 21 frontend tests, TypeScript/Vite build, Swift helper build, Tauri arm64 packaging, strict signature verification, exact installed executable parity, and a valid 2940×1912 runtime PNG artifact at `artifacts/tauri-e2e/s33-shoteye-runtime.png`. Physical clipboard acceptance remains pending desktop interaction access.

## Sprint S34-export-formats — 2026-08-30

- [x] Add Rust-side safe extension selection for PNG, JPEG, and TIFF.
- [x] Encode non-PNG exports from the canonical capture without changing Rust-owned preview/Copy state.
- [x] Expose matching PNG/JPEG/TIFF filters in the native Save dialog.
- [x] Add decode-and-dimension regression coverage and repackage/install the exact arm64 app.
- [ ] Independently exercise the installed Save dialog for each format and inspect the resulting files.

### Review

Focused verification passed: 22 Rust tests, 21 frontend tests, TypeScript/Vite build, Swift helper build, Tauri arm64 packaging, strict signature verification, exact installed executable parity, and a valid 2940×1912 runtime PNG artifact at `artifacts/tauri-e2e/s34-shoteye-runtime.png`. Physical Save interaction remains pending desktop automation access.

## Sprint S35-native-finder-drag — 2026-08-30

- [x] Audit the available Tauri drag-out plugin and reject it for the current canonical PNG workflow because its default archive promise path does not materialize a file.
- [x] Add a macOS-only Cocoa/AppKit bridge that starts an `NSURL`-backed `NSDraggingItem` from the current ShotEye editor event.
- [x] Stage the current canonical annotated PNG in a private `0700` directory retained by managed Rust state until app shutdown.
- [x] Add the React Drag control with capture-empty, in-flight, success, and native-error states.
- [x] Add private product-named staging coverage; run focused Rust/frontend tests, build, package, install, and strict-signature checks.
- [ ] Physically drag from the exact installed package into Finder and reopen the dropped PNG to verify bytes and dimensions.

### Review

Focused verification passed: 23 Rust tests, 21 frontend tests, TypeScript/Vite build, `cargo check`, arm64 Tauri packaging, exact installed/built executable parity, exact bundled selector parity, one ShotEye process, and `codesign --verify --deep --strict`. The installed bundle is `/Applications/ShotEye.app`; the package artifact is `/Users/colbert1/shoteye/tauri-app/src-tauri/target/release/bundle/dmg/ShotEye_0.1.0_aarch64.dmg`; the latest runtime artifact is `artifacts/tauri-e2e/s35b-shoteye-runtime.png` (2940×1912 PNG). Native Finder drag acceptance remains unverified because this session cannot perform desktop pointer automation with Accessibility access.

## Sprint S35-drag-review-hardening — 2026-08-30

- [x] Replace stale `NSApp.currentEvent` reliance with a fresh AppKit mouse-down event at the current pointer location.
- [x] Render a visible PNG drag image and clean the private staged file when the AppKit drag session ends.
- [x] Serialize export preparation and gate background drag readiness by the latest capture/annotation revision.
- [x] Re-run focused tests, package the exact arm64 app, install it, and verify strict signature/resource/process/runtime evidence.
- [ ] Physically drag from the exact installed package into Finder and reopen the dropped PNG to verify bytes and dimensions.

### Review

Review findings were addressed in the native Cocoa bridge and React export queue. Focused Rust/frontend verification remains green (23/21 tests), the packaged app launches from `/Applications/ShotEye.app` as one process, strict signature verification passes, and the runtime artifact is `/Users/colbert1/shoteye/artifacts/tauri-e2e/s35b-shoteye-runtime.png` with a valid PNG header and 2940×1912 dimensions. Physical Finder drop acceptance remains an operator-gated follow-up.

## Sprint S36-shoteye-product-path-and-capture-hardening — 2026-08-30

- [x] Make root packaging and launch scripts build only the Tauri ShotEye application.
- [x] Isolate the historical Swift prototype under `legacy-swift/` so root operations cannot create a competing screenshot app.
- [x] Use an explicit host architecture target and validate app/helper Mach-O architecture and executable bits.
- [x] Make global shortcut readiness atomic and register the frontend event listener before reporting readiness.
- [x] Prevent native shortcut capture while recording and preserve distinct Command/Control plus extended key support.
- [x] Clear crop drafts on tool changes and pointer cancellation; make delayed native drag startup cancellation-safe.
- [x] Reject partial multi-monitor composites when any intersecting display read fails.
- [x] Run focused tests, package, install, and verify the exact arm64 app and runtime evidence.
- [ ] Complete physical Screen Recording, secondary-display, shortcut, and Finder drag/drop acceptance with Accessibility/TCC enabled.

### Review

Focused verification passed: 24 Rust tests, 24 frontend tests, TypeScript/Vite build, root package script, root launch smoke check, legacy Swift manifest isolation check, architecture validation, exact installed `/Applications/ShotEye.app` launch as one process, strict signature validation, and a valid 2940×1912 PNG artifact at `artifacts/tauri-e2e/s37-shoteye-runtime.png`. The root smoke assertion now matches only the exact ShotEye executable suffix, avoiding self-matches from `ps` arguments and correctly accepting the existing single-instance process. The package remains ad-hoc signed and physical desktop acceptance is still an explicit external gate.

## Sprint S37-product-status-surface — 2026-08-30

- [x] Remove the diagnostic toolbar IPC acknowledgement and its framework-facing status output.
- [x] Keep product status focused on capture, permission, editing, shortcut, and export outcomes.
- [x] Update the specification and release tracker to reflect the user-facing status contract.
- [ ] Repeat packaged interactive capture and export acceptance after Screen Recording and Accessibility permissions are authorized.

### Review

The editor no longer calls the removed `editor_action` command when selecting tools, and the footer no longer displays the backend platform. Focused tests and TypeScript/Vite build are the required regression checks; packaged physical capture remains permission-gated.

## Sprint S42-export-freshness-hardening — 2026-08-30

- [x] Add proof-first coverage for stable export preparation, revision-change retry, and bounded instability failure.
- [x] Use latest synchronous capture, dimensions, and annotation refs for Copy, Save, and Drag preparation.
- [x] Gate async preparation with the capture/annotation revision so an older annotated PNG cannot be reported ready.
- [x] Run the focused regression, full frontend suite (31 tests), TypeScript/Vite build, Rust suite (24 tests), arm64 package, exact install, strict signature, helper preflight, and PNG artifact checks.
- [ ] Run an independent packaged UI acceptance for rapid annotation changes followed by Copy, Save, and Finder Drag.

### Review

S42 closes the stale React-closure race at the export boundary. The installed `/Applications/ShotEye.app` is one exact `shoteye` process with no stale framework executable; its ad-hoc package passes strict local verification and the fresh runtime artifact is `artifacts/tauri-e2e/s42-shoteye-runtime.png` (2940×1912 PNG). Physical desktop capture and public signing remain external gates.

## Sprint S44-exclusive-export-actions — 2026-08-30

- [x] Add a shared async export guard for user-triggered Copy, Save, and Drag actions.
- [x] Keep the guard through latest-revision preparation and native export/drag startup.
- [x] Report an actionable busy status for a competing export request.
- [x] Prove the pending-action block and rejection-release paths with focused tests.
- [x] Run the full frontend suite (33 tests), Rust suite (24 tests), production build, arm64 package, exact install, shared verifier, and fresh PNG evidence.
- [ ] Complete independent packaged UI acceptance for rapid annotate → Copy/Save/Drag changes.

### Review

S44 prevents overlapping native exports while preserving the S42 latest-revision guarantee. `/Applications/ShotEye.app` is the rebuilt package, the exact process and bundle checks pass, and `artifacts/tauri-e2e/s44-shoteye-runtime.png` is a valid 2940×1912 PNG. Physical desktop interaction and public Apple signing remain unproven.

## Sprint S45-unified-native-operation-lane — 2026-08-30

- [x] Replace separate capture/export locks with one native-operation guard.
- [x] Prevent capture from hiding the editor or invoking a native adapter while Copy, Save, or Drag is pending.
- [x] Preserve the busy status and release the guard on all completion and failure paths.
- [x] Run focused/full frontend tests (33), Rust tests (24), production build, arm64 packaging, exact install, shared verifier, and fresh PNG evidence.
- [ ] Complete independent packaged UI acceptance for rapid capture/export contention and physical selector behavior.

### Review

S45 closes the remaining local overlap between capture and export. The installed `/Applications/ShotEye.app` passes identity, architecture, parity, strict signature, helper preflight, DMG, and one-process checks; `artifacts/tauri-e2e/s45-shoteye-runtime.png` is valid 2940×1912 PNG evidence. Physical desktop acceptance and public Apple signing remain external gates.

## Sprint S46-native-menu-command-surface — 2026-08-30

- [x] Define a unique, product-branded native File/Capture/Edit/Help menu model.
- [x] Install the menu through Tauri's native menu API and route actions through current React refs.
- [x] Keep menu commands on the existing guarded capture/export and canonical image paths.
- [x] Add focused menu-model coverage for unique IDs and primary workflow actions.
- [x] Run the full frontend suite (35 tests), Rust suite (24 tests), production build, arm64 package, exact install, shared verifier, and process check.
- [ ] Complete independent Accessibility-enabled menu-click acceptance on the installed package.

### Review

S46 adds native command discoverability without creating a second implementation path. Menu callbacks read current handler refs, so Open/Paste/Copy/Save and capture commands retain the same latest-image and exclusive-operation behavior as toolbar and keyboard entry points. The menu-capable package is installed at `/Applications/ShotEye.app`; local identity, architecture, parity, strict signature, helper preflight, DMG, and one-process checks pass. Physical menu/selector interaction and Developer ID/notarized release remain external gates.

## Sprint S47-transactional-display-selection — 2026-08-30

- [x] Add a pure geometry coverage check to reject selections crossing gaps between offset displays.
- [x] Return and surface a dedicated display-gap failure without creating a partial transparent capture.
- [x] Make bundled helper launch require a positive permission probe; route denied/inconclusive probes to the system fallback.
- [x] Add deterministic helper geometry self-tests and run them from the install verifier.
- [x] Run the full frontend suite (35 tests), Rust suite (25 tests), Swift helper build, arm64 package, exact install, verifier, and PNG evidence.
- [ ] Add mixed-DPI native-pixel composition tests and independent physical cross-display acceptance.

### Review

S47 closes a real compositor correctness hole and a fail-open helper path. The exact installed `/Applications/ShotEye.app` passes bundle identity, arm64 parity, strict local signing, helper permission preflight, geometry self-test, DMG, and one-process checks; `artifacts/tauri-e2e/s47-shoteye-runtime.png` is a valid 2940×1912 PNG artifact. Physical selector/menu interaction, mixed-DPI proof, and Developer ID/notarized release remain external gates.

## Sprint S48-bounded-native-capture-lifecycle — 2026-08-30

- [x] Replace unbounded native `status()` waits with an owned, polled child process.
- [x] Kill and reap a child after the five-minute deadline, returning a typed timeout error.
- [x] Prevent helper timeouts from falling through to a second interactive system selector.
- [x] Preserve the existing frontend restoration/guard-release path and add focused timeout coverage.
- [x] Run the full frontend suite (35 tests), Rust suite (26 tests), Swift helper build, arm64 package, exact install, verifier, and PNG evidence.
- [ ] Complete physical selector cancellation/timeout and cross-display acceptance on the exact installed package.

### Review

S48 removes the indefinite native wait that could reproduce a permanently busy or apparently frozen capture flow. The installed `/Applications/ShotEye.app` passes identity, architecture, parity, strict local signing, helper permission preflight, geometry self-test, DMG, and one-process verification; `artifacts/tauri-e2e/s48-shoteye-runtime.png` is a valid 2940×1912 PNG. Physical desktop interaction and public Apple signing remain unverified external gates.

## Sprint S43-installed-package-verification — 2026-08-30

- [x] Add `scripts/verify_app.sh` for exact installed ShotEye identity, architecture, helper, signature, parity, and stale-executable checks.
- [x] Add optional PNG header and dimension validation to the install verifier.
- [x] Route `script/build_and_run.sh --verify` through the shared verifier.
- [x] Verify the installed package and `artifacts/tauri-e2e/s42-shoteye-runtime.png` with the new gate.
- [ ] Extend the verifier only after an independent desktop harness can exercise physical selection, Copy/Save, and Finder Drag.

### Review

The package gate passes for `/Applications/ShotEye.app`: `shoteye`/`com.moltbagus.shoteye.tauri`, arm64 binaries, matching installed/build binaries, strict signature, no stale `tauri-app`, DMG, helper preflight exit 0, one process, and valid 2940×1912 PNG evidence. It deliberately remains weaker than physical UI acceptance and public Apple signing.

## Sprint S38-native-executable-identity — 2026-08-30

- [x] Rename the Rust package/library, npm package, and packaged process from `tauri-app` to `shoteye`.
- [x] Update root package, launch, and log verification predicates to the product executable.
- [x] Replace the installed stale bundle through a recoverable Trash move so no obsolete executable remains in `Contents/MacOS`.
- [x] Rebuild, install, and verify one product-named process with strict signature validation.
- [ ] Repeat physical capture, shortcut, and Finder drag acceptance after Screen Recording and Accessibility permissions are authorized.

### Review

The packaged bundle contains only `Contents/MacOS/shoteye`; `/Applications/ShotEye.app` launches one `shoteye` process, and the prior stale bundle was moved to the user Trash rather than left as a competing application. The package remains ad-hoc signed and physical desktop acceptance remains permission-gated.

## Sprint S39-release-packaging-gate — 2026-08-30

- [x] Add `--release` packaging mode with complete Developer ID identity validation.
- [x] Require a complete Apple notarization credential set before release builds.
- [x] Validate strict code signing, Gatekeeper acceptance, and a stapled notarization ticket for release output.
- [x] Prove the available local development certificate is rejected before a release build starts.
- [ ] Run the release mode with real Apple Developer credentials and publish the notarized DMG.

### Review

The local build path remains available for ad-hoc evaluation, while the release path now fails closed when no real Developer ID Application identity or notarization credentials are present. On this Mac, only `ShotEye Local Development` is available, so the external Apple credential gate remains open.

## Sprint S40-helper-screen-recording-preflight — 2026-08-30

- [x] Add `--check-permission` to the bundled AppKit selector using a non-prompting Core Graphics preflight.
- [x] Probe helper-specific Screen Recording access before creating a visible native overlay.
- [x] Fall back to macOS `screencapture` when the helper returns its reserved permission-denied exit code or cannot be executed, without treating cancellation as permission failure.
- [x] Rebuild, install, and verify the exact arm64 package, helper probe, process identity, bundle parity, and strict signature.
- [ ] Physically complete area selection, cancellation, Copy/Save, and secondary-monitor acceptance with the exact installed package.

### Review

The installed helper probe returned success without opening a consent sheet, the package contains no stale `tauri-app` executable, and exactly one `/Applications/ShotEye.app/Contents/MacOS/shoteye` process is running. Focused Rust/frontend checks and packaging passed. Physical TCC behavior during a drag remains unverified by this session.

## Sprint S41-startup-shortcut-recovery — 2026-08-30

- [x] Add pure shortcut-response and startup-recovery helpers.
- [x] Clear a saved custom shortcut when native startup registration rejects it and restore the known active default display.
- [x] Keep explicit user replacement failures from changing the active shortcut or local preference.
- [x] Run the focused regression, full frontend suite, TypeScript/Vite build, arm64 package build, and exact installed-process checks.
- [ ] Physically exercise shortcut conflict handling and global invocation on the exact installed package.

### Review

The new pure regression covers accepted native responses, rejected saved custom shortcuts, default preservation, and accepted custom shortcuts. The installed package launches as one product-named process with no stale executable. Physical global-key delivery remains unverified because this session has no accessibility-enabled desktop harness.

## Sprint S49-status-and-package-evidence-hardening — 2026-08-30

- [x] Add a focused status-epoch regression for delayed startup status results.
- [x] Guard startup permission, shortcut, menu, and listener status commits against later user actions.
- [x] Keep background Drag prewarming in revision-scoped WebView memory and make guarded exports the only Rust-state writer.
- [x] Bound the helper permission probe with a two-second owned-child timeout and system-selector fallback.
- [x] Replace the hanging Finder cosmetic DMG step with deterministic direct `hdiutil` creation.
- [x] Add read-only mounted-DMG payload verification to `scripts/verify_app.sh --dmg`.
- [x] Run frontend/Rust suites, production build, arm64 package, installed verifier, and exact DMG payload verifier.
- [ ] Complete physical area/window/secondary-display capture, menu, shortcut, and Finder-drop acceptance on the exact package.
- [ ] Obtain Developer ID Application signing and notarization credentials for public distribution.

### Review

S49 closes two locally reproducible reliability gaps: delayed startup promises can no longer overwrite a later user result, and Drag prewarming cannot overwrite Rust capture state while a new capture is in flight. The helper permission probe is bounded, packaging no longer hangs in Finder automation, and the exact DMG payload now passes the install verifier. Evidence: 36 frontend tests, 27 Rust tests, an arm64 package, `/Applications/ShotEye.app`, and `artifacts/tauri-e2e/s49-shoteye-runtime.png` (valid 2940×1912 PNG structure). The PNG is structurally valid but visually black in this desktop capture environment, so it is not claimed as UI proof. Physical acceptance and Apple public signing remain open.

## Sprint S50-mixed-DPI-compositor-evidence — 2026-08-30

- [x] Extract the display compositor behind the existing native capture path.
- [x] Make output RGBA byte order and nearest-neighbor interpolation explicit.
- [x] Add a permission-free mixed-DPI self-test covering dimensions, seam ownership, opaque coverage, and all output pixels.
- [x] Run frontend/Rust suites, Swift helper build/self-tests, arm64 package, installed verifier, exact mounted DMG verifier, and report generation.
- [ ] Complete physical secondary-display capture and Developer ID/notarized release acceptance.

### Review

S50 closes the deterministic compositor evidence gap without changing the Rust `capture_area` boundary. The helper self-tests and both exact package verification paths pass. The fresh runtime artifact is structurally valid (2940×1912 RGBA PNG) but visually black in this session, so it is not claimed as physical UI or capture proof. Physical pointer/Finder acceptance and Apple signing remain pending.

## Sprint S51-compositor-coordinate-hardening — 2026-08-30

- [x] Replace implicit native crop integral rounding with explicit floor-min/ceil-max backing-pixel bounds.
- [x] Apply the same deterministic bounds to compositor destination edges.
- [x] Add synthetic vertical bands and fractional selection edges to the permission-free full-output self-test.
- [x] Rebuild, install, and verify the exact arm64 app and mounted DMG payload.
- [ ] Complete physical secondary-display capture and Developer ID/notarized release acceptance.

### Review

S51 hardens the native coordinate boundary without changing the frontend or Rust command contract. The selector now has executable proof for vertical orientation, fractional edges, seam ownership, alpha coverage, and output dimensions. The installed app and exact DMG verifier pass; physical desktop capture and Apple signing remain pending.

## Sprint S52-capture-boundary-verification — 2026-08-30

- [x] Extract the production display crop transform into a pure helper.
- [x] Add top-row-first synthetic upper/lower crop tests with exact backing rectangles and pixel assertions.
- [x] Add the crop-transform helper self-test to installed and mounted-DMG verification.
- [x] Bound the Screen Recording settings opener with owned-child timeout handling.
- [x] Rebuild, install, and verify the exact arm64 app and DMG payload.
- [ ] Complete physical area/window/secondary-display/Finder acceptance and Developer ID/notarized release.

### Review

S52 closes the remaining testable crop-boundary gap and prevents permission-settings recovery from becoming another unbounded native operation. The installed app and exact DMG verifier pass all native self-tests; physical UI interaction and Apple distribution signing remain external gates.

## Sprint S54-startup-shortcut-conflict-recovery — 2026-08-30

- [x] Make default global-shortcut registration best-effort so a conflict cannot abort app startup.
- [x] Track whether the current shortcut is actually registered so startup can retry the same default value.
- [x] Preserve atomic replacement semantics for explicit user shortcut changes.
- [x] Add focused Rust regression coverage and rerun the packaged verification path.
- [ ] Complete physical shortcut-conflict and global-invocation acceptance on the exact installed package.

### Review

S54 keeps the editor launchable when `CommandOrControl+Shift+Y` is occupied. The Rust suite passes 28 tests, the frontend suite passes 37 tests, the production build and arm64 package succeed, and the exact installed app plus mounted DMG verifier pass. Physical global-key delivery and Developer ID/notarization remain external release gates.

## Sprint S55-canonical-installed-bundle-runner — 2026-08-30

- [x] Confirm the root runner launched the build-tree bundle instead of the permission-authorized installed bundle.
- [x] Add a recoverable exact-bundle installer for `/Applications/ShotEye.app`.
- [x] Route `run`, `--logs`, and `--verify` through the installed bundle after packaging.
- [x] Add shell syntax and invalid-argument checks for the installer and runner.
- [ ] Re-authorize Screen Recording for the newly installed exact bundle and complete physical capture acceptance.

### Review

The prior root runner packaged one app but opened the build-tree copy, while the verifier and operator settings targeted `/Applications/ShotEye.app`. S55 closes that identity mismatch: the runner now stops the exact old process, stages and validates the fresh package, moves the prior installed bundle to a recoverable temporary backup, and opens/verifies the same canonical path. Package and mounted-DMG checks remain required after the new install; physical Screen Recording, shortcut, Finder drag, and public signing acceptance remain open.

## Sprint S56-native-display-read-evidence — 2026-08-30

- [x] Add a noninteractive Swift helper mode that preflights TCC and reads the main display through `CGDisplayCreateImage`.
- [x] Keep the display-read self-test free of overlays, pointer events, and consent requests.
- [x] Run the new gate in installed-app and mounted-DMG verification.
- [x] Record the actual helper preflight and display-read exit codes in both verification reports.
- [x] Rebuild, install, and verify the arm64 ShotEye package with fresh S56 reports.
- [ ] Complete physical area drag, secondary-display, Copy/Save, Finder drag, shortcut, and Developer ID/notarization acceptance.

### Review

S56 strengthens the evidence boundary between “permission preflight says yes” and “the exact bundled helper can actually read display pixels.” The new self-test passes for `/Applications/ShotEye.app` and the exact mounted DMG payload. It does not replace physical area selection or public Apple signing evidence.

## Sprint S57-permission-action-concurrency — 2026-08-30

- [x] Audit the repeated Screen Recording permission prompt path across toolbar and native-menu entry points.
- [x] Add one shared async guard for permission request and settings actions.
- [x] Disable both permission controls while the guarded action is pending and show an in-progress label.
- [x] Guard delayed permission success/failure status with the current status epoch.
- [x] Rebuild, install, and verify the exact arm64 app and mounted DMG payload.
- [ ] Complete physical permission-dialog, area-drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarized-release acceptance.

### Review

S57 closes the concrete concurrency defect found by the permission UX audit. The request and settings actions now share the tested exclusive-action primitive, refuse to overlap the native capture/export lane, and delayed native results cannot replace a newer user-owned status. Full frontend/Rust checks, the TypeScript/Vite build, arm64 packaging, exact installation, and both package verifiers pass. App-level pointer/dialog acceptance remains unavailable in this session.

## Sprint S58-canonical-artifact-verification — 2026-08-30

- [x] Audit installer and verifier paths for stale DMG and source-bundle identity drift.
- [x] Derive the verifier's built DMG path from the host architecture and expected version instead of selecting the first historical match.
- [x] Strict-verify the source app before stopping the installed process or replacing `/Applications/ShotEye.app`.
- [x] Re-run the exact installed-app and mounted-DMG verification paths with fresh reports.
- [ ] Complete physical permission-dialog, area-drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarized-release acceptance.

### Review

S58 closes two package-tooling paths that could make a valid local build appear inconsistent: arbitrary historical DMG selection and replacement from an unsigned source bundle. Shell syntax, frontend tests, strict installation, exact identity, helper self-tests, display-read, and mounted-DMG verification pass. Physical desktop acceptance and public Apple signing remain open.

## Sprint S59-canonical-writer-concurrency — 2026-08-30

- [x] Audit every frontend action that can replace Rust-owned canonical image state.
- [x] Serialize Open, Paste, and Crop through the existing exclusive native-operation lane.
- [x] Capture operation, import/crop, and export terminal statuses only while their status epoch is current.
- [x] Kill and reap a native child if polling itself returns an error.
- [x] Run focused frontend/Rust tests, production build, arm64 package, exact install, and installed/DMG verification.
- [ ] Complete physical permission-dialog, area-drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarized-release acceptance.

### Review

S59 closes a concrete data-integrity race: Open, Paste, or Crop could previously overwrite the canonical Rust image while capture/export was in flight, and late terminal messages could replace a newer user result. The shared lane now covers all canonical writers, status epochs cover each async terminal path, and native polling errors clean up their child before returning. Frontend tests, Rust tests, production build, arm64 package, exact install, and mounted-DMG verification are required evidence; physical desktop acceptance and public Apple signing remain open.

## Sprint S60-native-dispatch-evidence — 2026-08-30

- [x] Isolate bundled-helper versus system-selector dispatch behind an injectable runner seam.
- [x] Cover inconclusive/denied helper probes and helper permission exit fallback.
- [x] Cover helper cancellation and ordinary failure without starting a second selector.
- [x] Cover helper spawn failure fallback and timeout no-fallback behavior.
- [x] Run the Rust suite and retain the existing package verification path for the production wiring.
- [ ] Complete physical permission-dialog, area-drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarized-release acceptance.

### Review

S60 turns the highest-risk selector-policy branches into executable evidence without changing the public `capture_area` command. The production helper still requires a positive non-prompting probe, missing/denied helpers fall back to macOS `screencapture`, cancellation and ordinary helper failures remain terminal, and timeouts do not launch a second interactive selector. Rust tests pass; physical desktop interaction and public Apple signing remain open.

## Sprint S61-frontend-capture-lifecycle — 2026-08-30

- [x] Audit the current `runCapture` hide/action/restore lifecycle and status precedence.
- [x] Extract the lifecycle into a small testable helper without changing the native command boundary.
- [x] Cover successful capture, hide failure, action failure, and restore failure behavior.
- [x] Run focused frontend/Rust checks, package, install, and verify the exact arm64 app and DMG.
- [ ] Complete physical capture, Copy/Save, multi-monitor, shortcut, and Developer ID/notarization acceptance.

### Review

S61 makes the editor lifecycle independently executable: a capture action is attempted only after hide succeeds, and the editor is always offered show/focus recovery. Restore errors remain higher priority than capture errors, matching the previous user-visible behavior. Verification passed with 41 frontend tests, 34 Rust tests, the production build, exact arm64 installation, strict signature checks, and mounted-DMG payload checks. Evidence: `artifacts/tauri-e2e/s61-shoteye-verification.txt` and `artifacts/tauri-e2e/s61-dmg-verification.txt`. Physical desktop acceptance and public Apple signing remain external release gates.

## Sprint S62-frontend-restoration-edge — 2026-08-30

- [x] Cover `show()` failure while still attempting `setFocus()`.
- [x] Run the frontend suite/build and refresh the exact arm64 app and DMG verification.
- [x] Update the final S62 evidence and retain physical/signing release gates.

### Review

S62 closes the remaining restoration edge in the lifecycle seam: a failed show call no longer prevents the best-effort focus call, and the first restoration error remains available for user-facing reporting. Verification passed with 42 frontend tests, the production build, exact arm64 installation, strict signature checks, helper self-tests, and mounted-DMG payload validation. Evidence: `artifacts/tauri-e2e/s62-shoteye-verification.txt` and `artifacts/tauri-e2e/s62-dmg-verification.txt`. Physical desktop acceptance and public Apple signing remain external release gates.

## Sprint S64-native-selection-interaction — 2026-08-30

- [x] Audit native selector gesture normalization and identify the shared interaction boundary.
- [x] Centralize forward/reverse drag normalization and minimum-size rejection.
- [x] Add a deterministic selector interaction self-test for valid, reversed, and undersized gestures.
- [x] Run Swift/Rust/frontend checks, package, install, and verify the exact arm64 app and DMG.
- [ ] Complete physical area selection, Copy/Save, multi-monitor, shortcut, Finder drag, and Developer ID/notarization acceptance.

### Review

S64 strengthens the selector's input boundary without creating an overlay: mouse-up acceptance and the visible selection outline now use a shared interaction state reducer, valid completion clears the gesture before capture handoff, and undersized completion/Escape/deactivation return to idle. The permission-free self-test covers forward/reverse drags, width/height minimum failures, completion reset, and cancellation reset. Verification passed with the Swift helper build, 42 frontend tests, 34 Rust tests, exact arm64 installation, strict signature checks, helper self-tests, and mounted-DMG validation. Evidence: `artifacts/tauri-e2e/s64-shoteye-verification.txt` and `artifacts/tauri-e2e/s64-dmg-verification.txt`. Physical pointer acceptance and public Apple signing remain external release gates.

## Sprint S63-runtime-capture-evidence — 2026-08-30

- [x] Re-audit the exact installed ShotEye bundle and running process after S62.
- [x] Confirm the bundled helper's non-prompting permission and display-read checks.
- [x] Probe a real noninteractive macOS fullscreen capture and validate its PNG header and dimensions.
- [x] Record that the execution environment returns an all-black desktop image, so this artifact cannot prove visible pixels or interactive pointer selection.
- [ ] Complete physical area selection, Copy/Save, multi-monitor, shortcut, Finder drag, and Developer ID/notarization acceptance.

### Review

S63 separates permission evidence from visual/interactive evidence. The exact helper preflight and display-read path succeed, and `/usr/sbin/screencapture` returns a structurally valid 2940×1912 PNG, but the captured desktop is all black in this environment. The artifact is therefore useful as a boundary signal only, not as proof of a visible screenshot or physical selector workflow. Evidence: `artifacts/tauri-e2e/s63-system-fullscreen.png`.

## Sprint S65-atomic-export-write — 2026-08-30

- [x] Audit the canonical Save path for partial-destination risk.
- [x] Write encoded exports to a unique same-directory staging file, sync them, and atomically rename them into place.
- [x] Add a Rust regression proving an existing destination is replaced and no staging file remains.
- [x] Run frontend/Rust checks, package, install, and verify the exact arm64 app and DMG.
- [ ] Complete physical area selection, Copy/Save, multi-monitor, shortcut, Finder-drag, and Developer ID/notarization acceptance.

### Review

S65 closes the concrete Save durability gap: `save_capture` now validates and fully encodes before staging the complete payload beside the destination, then replaces it with one atomic rename. The test proves replacement and staging cleanup. Verification passed with 42 frontend tests, 35 Rust tests, TypeScript/Vite build, Swift helper build, exact arm64 installation, strict signature checks, helper self-tests, and mounted-DMG validation. Physical desktop interaction and public Apple signing remain open.

## Sprint S66-packaged-interaction-evidence — 2026-08-30

- [x] Launch the exact `/Applications/ShotEye.app` package and verify the foreground process remains alive.
- [x] Launch a second request against the exact installed package and verify the single-instance guard leaves one ShotEye process.
- [x] Audit the macOS log stream for ShotEye crash, panic, or app-owned IPC failures after the fresh package launch.
- [x] Copy the verified arm64 DMG to `artifacts/releases/ShotEye_0.1.0_aarch64.dmg` and confirm byte-for-byte hash parity.
- [ ] Complete physical toolbar clicks, area drag, Copy/Save, and shortcut invocation with Accessibility/Computer Use access.
- [ ] Replace ad-hoc signing with Developer ID and complete notarization.

### Review

S66 proves fresh-package launch and single-instance behavior on the exact installed bundle. The log audit found no ShotEye crash or panic; the WebContent/XPC errors observed are from the restricted automation environment and are not treated as app-level acceptance. Computer Use could not start its Node runtime and `osascript` was denied Assistive Access, so toolbar, drag, clipboard, and Save interactions remain explicitly unproven. The latest ad-hoc arm64 DMG is available under `artifacts/releases/`.

## Sprint S67-release-gate-audit — 2026-08-30

- [x] Confirm the packaged arm64 evaluation artifact remains available at the stable release path.
- [x] Run the public release packaging preflight with the current keychain state.
- [x] Confirm release packaging fails closed before a build when no Developer ID identity is configured.
- [x] Reconfirm the desktop UI automation bridge is unavailable on this host and preserve physical UI acceptance as an open gate.
- [ ] Obtain Apple Developer ID/notarization credentials and complete the physical packaged interaction run.

### Review

S67 confirms the release boundary is honest: `./scripts/package_app.sh --release` exits before building with the actionable Developer ID requirement because this Mac has only the known local development certificate. The ad-hoc package remains available for local evaluation, while physical toolbar/capture/export and notarized-public-release evidence remain open.

## Sprint S68-toolbar-interaction-affordances — 2026-08-30

- [x] Audit the shared toolbar button hit target and keyboard focus behavior.
- [x] Set a 40px minimum button target and restore a high-contrast `:focus-visible` ring without changing product actions.
- [x] Run focused frontend tests, TypeScript/Vite build, Rust tests, shell syntax checks, and diff validation.
- [x] Repackage, install, and verify the exact arm64 ShotEye app and mounted DMG.
- [ ] Complete physical toolbar activation, area drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarization acceptance.

### Review

S68 improves the shared editor control surface without changing capture or export behavior. The installed package is running as one process and both exact-package verification reports pass. The available automation environment still cannot independently exercise physical pointer/keyboard interaction, and the package remains ad-hoc rather than Developer ID signed.

## Sprint S69-stable-toolbar-iconography — 2026-08-30

- [x] Audit toolbar glyph rendering for platform-dependent Unicode symbols.
- [x] Replace action glyphs with stable accessible inline SVG icons while preserving labels and actions.
- [x] Run 42 frontend tests, 35 Rust tests, TypeScript/Vite build, shell syntax, and diff checks.
- [x] Repackage, install, and verify the exact arm64 ShotEye app and mounted DMG.
- [ ] Complete physical toolbar activation, area drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarization acceptance.

### Review

S69 improves toolbar consistency in macOS WebKit without changing the command boundary or keyboard behavior. The newly packaged app is installed and the exact app and DMG verifiers pass. Physical interaction and public signing remain open external gates.

## Sprint S70-bounded-clipboard-operations — 2026-08-30

- [x] Audit clipboard import and Copy for unbounded native helper processes.
- [x] Route both clipboard paths through the owned kill/reap timeout boundary.
- [x] Add actionable Copy timeout handling while preserving private staging cleanup.
- [x] Run 42 frontend tests, 35 Rust tests, TypeScript/Vite build, and diff checks.
- [x] Repackage, install, and verify the exact arm64 ShotEye app and mounted DMG.
- [ ] Complete physical clipboard, Save, drag-out, area drag, shortcut, and Developer ID/notarization acceptance.

### Review

S70 closes a native-operation hang path that could leave the editor apparently unresponsive during clipboard work. The exact installed app and mounted DMG verify successfully, and the shared timeout boundary is covered by the Rust child-lifecycle regression. Physical clipboard behavior and public signing remain open.

## Sprint S71-latest-revision-save-ordering — 2026-08-30

- [x] Audit the Save flow for edits made while the destination dialog is open.
- [x] Move rendered-export preparation after destination selection.
- [x] Run 42 frontend tests, 35 Rust tests, TypeScript/Vite build, diff checks, and an explicit Save-order assertion.
- [x] Repackage, install, and verify the exact arm64 ShotEye app and mounted DMG.
- [ ] Complete physical Save-dialog, annotated export, area drag, shortcut, Finder-drag, and Developer ID/notarization acceptance.

### Review

S71 closes a stale-revision export window in Save. The destination dialog remains user-controlled, but final rendering now starts only after the path is chosen and remains protected by the stable-revision guard. Exact installed-app and mounted-DMG verification pass; physical export and public signing remain open.

## Sprint S72-single-supported-product-layout — 2026-08-30

- [x] Inspect the in-repo `dist/Shotser.app` bundle and verify its legacy identity.
- [x] Move the stale bundle recoverably to `legacy-swift/archived/Shotser.app`.
- [x] Add packaging and verification guards against duplicate `.app` bundles directly under root `dist/`.
- [x] Run shell syntax/diff checks and verify the exact arm64 ShotEye app and mounted DMG.
- [ ] Complete physical area drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarization acceptance.

### Review

S72 removes the duplicate launch target that could make users open the old Swift app instead of ShotEye. The old bundle remains recoverable for historical inspection, while the supported root packaging path now fails closed if another app bundle is placed in `dist/`.

## Sprint S73-duplicate-app-guard-verification — 2026-08-30

- [x] Re-run the exact installed ShotEye verifier after the S72 guarded rebuild.
- [x] Prove package and verification scripts reject a temporary duplicate `.app` under root `dist/`.
- [x] Remove the temporary probe and confirm no root `dist/*.app` remains.
- [x] Confirm one active `/Applications/ShotEye.app` process and current origin parity.
- [ ] Complete physical area drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarization acceptance.

### Review

S73 turns the duplicate-product fix into explicit evidence. The happy-path package remains verifiable and the negative guard fails closed before any build or launch work; the old legacy bundle is preserved only in the archive.

## Sprint S74-permission-category-clarity — 2026-08-30

- [x] Audit the repeated permission prompt report against the exact installed app identity and native preflight path.
- [x] Add a failing Rust regression for the missing macOS permission-category and no-audio explanation.
- [x] Clarify permission status/settings copy and the `NSScreenCaptureUsageDescription` while preserving non-prompting capture behavior.
- [x] Run focused frontend/Rust checks, package and install the exact arm64 app, and verify the mounted DMG.
- [x] Copy the verified DMG to `artifacts/releases/ShotEye_0.1.0_aarch64.dmg` and confirm hash parity.
- [ ] Obtain Developer ID signing and complete physical Screen Recording, area-drag, Copy/Save, shortcut, and Finder-drag acceptance.

### Review

S74 confirms that the repeated prompt symptom is primarily an ad-hoc TCC identity-continuity limitation, not an audio request or an unconditional prompt in ShotEye's capture path. The shipped guidance now matches Apple's settings label and explicitly says screen pixels only. Focused tests, the exact installed package, mounted DMG, helper preflight/display-read, and stable artifact parity passed. Developer ID signing and physical desktop interaction remain external release gates.

## Sprint S75-async-crop-stale-result — 2026-08-30

- [x] Add a focused crop revision predicate regression for unchanged and advanced source revisions.
- [x] Read crop inputs through synchronous refs instead of the potentially stale React closure.
- [x] Advance the image-edit revision synchronously for image replacement and annotation-history mutations.
- [x] Reject stale crop work after asynchronous image preparation and before visible state commit.
- [x] Defer crop persistence to the guarded Copy, Save, and Drag export boundary so delayed crop work cannot write stale Rust-owned bytes.
- [x] Run focused/full frontend checks, Rust tests, package/install verification, and mounted-DMG verification.
- [ ] Add an App-level controllable async harness for Crop → Reset and Crop → annotation interleavings.
- [ ] Complete physical area drag, Copy/Save, shortcut, Finder-drag, secondary-display, and Developer ID/notarization acceptance.

### Review

S75 closes the confirmed React/native asynchronous crop race with a synchronous revision guard and removes the stale native-write window by keeping crop persistence at the existing export boundary. The latest exact installed app and refreshed DMG pass structural/package verification; the pure guard tests cover the invalidation contract, while full App-level promise interleavings and physical macOS interaction remain follow-up evidence gates.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the targeted read-only subagent review and a manual diff scan were completed. Simplify skipped because the substantive source diff is below the 30-line threshold.

## Sprint S76-appkit-selector-event-evidence — 2026-08-30

- [x] Audit the native selector event path and existing reducer self-test.
- [x] Add synthetic AppKit mouse event coverage through `SelectionView.mouseDown`, `mouseDragged`, and `mouseUp`.
- [x] Add synthetic Escape coverage through `SelectionView.keyDown`, including cancellation callback and state cleanup.
- [x] Verify key-capable panel and first-responder readiness without display capture or Accessibility permission.
- [x] Compile the selector and run the self-test from the packaged installed app and exact mounted DMG.
- [ ] Complete physical area-drag, Copy/Save, shortcut, Finder-drag, secondary-display, and Developer ID/notarization acceptance.

### Review

S76 closes the gap between pure selector-state tests and actual AppKit event dispatch. The exact package verifier now labels the combined reducer/AppKit event self-test explicitly; physical pointer interaction and public signing remain external gates.

Independent AppKit review was attempted through a subagent but timed out; the manual fallback audited event construction, responder setup, cleanup, and the passing exact-bundle self-test. No code-review skill invocation primitive is exposed in this session.

## Sprint S77-nested-helper-release-integrity — 2026-08-30

- [x] Audit the release signer checks against the separately executed bundled AppKit selector.
- [x] Require the selector to carry Developer ID authority and the same non-empty Team ID as the outer app.
- [x] Record the selector reducer/AppKit event self-test exit code in verifier reports.
- [x] Run shell syntax checks, the guarded release preflight, and local package/install plus mounted-DMG verification.
- [ ] Obtain Apple Developer ID credentials and complete physical capture, Copy/Save, Finder drag, and secondary-display acceptance.

### Review

S77 closes a release-integrity gap: a valid outer signature alone no longer permits a separately launched native selector to pass the release path. The local self-signed certificate is intentionally rejected, while the known-good ad-hoc package remains available for local evaluation. The exact event self-test result is now recorded as an observable exit code in evidence reports.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the read-only release audit and manual diff scan were completed. Simplify skipped because the source change is a focused shell/verifier hardening below the substantive-refactor threshold.

## Sprint S78-capture-single-instance-handoff — 2026-08-30

- [x] Reproduce the duplicate-launch race at the single-instance callback and hidden native selector boundary.
- [x] Add shared Rust capture activity ownership across area, window, fullscreen, and repeat capture commands.
- [x] Ignore duplicate-launch reveal while capture is active so native selection retains focus.
- [x] Add overlap rejection and RAII release regression coverage.
- [x] Run focused Rust/frontend checks, package/install, strict installed-app verification, and mounted-DMG verification.
- [ ] Complete Accessibility-enabled duplicate-launch and physical selector cancellation acceptance on the packaged app.

### Review

S78 fixes a real focus race: a second launch could previously reveal the hidden editor, deactivate the selector, and turn a valid capture into a cancellation. Capture activity now spans the native command lifetime, duplicate activation is ignored during that interval, and a dropped guard releases the state on every return path. Physical Accessibility-enabled confirmation remains an external acceptance gate.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the product audit, manual diff scan, and focused regression were completed. Simplify skipped because the change is a small state-boundary hardening.

## Sprint S79-release-verification-mode — 2026-08-30

- [x] Audit the current package identity and release evidence for a locally fixable reliability gap.
- [x] Add explicit local-only and `--release` verifier modes.
- [x] Require Developer ID authority and matching non-empty TeamIdentifier values for the app and bundled selector in release mode.
- [x] Require Gatekeeper assessment and stapled app/DMG notarization in release mode, while keeping mounted-DMG recursion scoped to the exact requested DMG.
- [x] Run shell syntax checks, local installed verification, and the expected release-gate rejection on the current ad-hoc package.
- [ ] Obtain Apple Developer ID/notarization credentials and rerun the release verifier successfully.
- [ ] Complete Accessibility-enabled physical area selection, Copy/Save, shortcut, Finder-drag, and secondary-display acceptance.

### Review

S79 makes package evidence honest and actionable: local strict verification now reports `local-only`, while `--release` fails before Gatekeeper/notarization when the installed app is ad-hoc. The exact local pass and negative release result are recorded in `artifacts/tauri-e2e/s79-local-installed-verification.txt` and `artifacts/tauri-e2e/s79-release-rejection.txt`. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the native/release subagent audit and manual verifier scan were completed. Simplify skipped because this is a focused shell-only hardening.

## Sprint S80-current-image-keyboard-actions — 2026-08-30

- [x] Audit the editor keyboard listener against image replacement paths.
- [x] Refresh the listener when the current capture changes so keyboard Copy/Save use current state after import, crop, or capture.
- [x] Run frontend tests/build and package the exact arm64 app.
- [x] Install and verify the exact app and mounted DMG; refresh the canonical download artifact.
- [ ] Complete physical keyboard Copy/Save and capture acceptance with Accessibility-enabled testing.

### Review

S80 closes a real stale-closure path in the editor: the keyboard listener now rebinds on `capture` changes while export preparation still reads synchronous refs for annotations and revisions. The new exact package is installed at `/Applications/ShotEye.app`; both installed and mounted-DMG reports pass structural/helper checks. Physical keyboard/UI interaction remains an external gate. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the read-only UI/native audits and manual diff scan were completed.

## Sprint S81-guarded-edit-menu-actions — 2026-08-30

- [x] Audit native Edit-menu callbacks against toolbar and keyboard mutation guards.
- [x] Centralize Undo, Redo, Clear, Reset, and Delete-equivalent mutation dispatch behind a capture-active guard.
- [x] Make Clear and Reset clear selection, crop, draw, move, and resize transient state.
- [x] Run frontend tests/build, package/install the exact arm64 app, and verify the installed app and mounted DMG.
- [x] Add deterministic packaged frontend-to-Rust IPC runtime-contract evidence.
- [ ] Complete Accessibility-enabled physical keyboard/menu, area-drag, Copy/Save, shortcut, Finder-drag, secondary-display, and Developer ID/notarized acceptance.

### Review

S81 closes a native-menu bypass that could mutate annotation state during capture or leave stale interaction drafts after Clear. Toolbar, keyboard, and native menu mutations now converge on one dispatcher; the exact app and DMG pass local package verification. The native audit also confirmed that existing verifier checks do not prove packaged frontend-to-Rust IPC, which remains the next focused evidence slice. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the read-only UI audit and manual diff scan were completed.

## Sprint S82-capture-and-shortcut-recovery — 2026-08-30

- [x] Audit the capture result branch for valid-image loss when window restoration fails.
- [x] Commit valid capture results before publishing show/focus restoration errors.
- [x] Retry the default shortcut after a rejected persisted custom shortcut.
- [x] Report explicitly when no global shortcut is active after fallback registration also fails.
- [x] Run frontend/Rust tests, build, exact arm64 package/install, and installed/mounted-DMG verification.
- [x] Add deterministic packaged frontend-to-Rust IPC runtime-contract evidence.
- [ ] Complete Accessibility-enabled physical keyboard/menu, area-drag, Copy/Save, shortcut, Finder-drag, secondary-display, and Developer ID/notarized acceptance.

### Review

S82 closes two user-facing false-failure paths: successful captures are no longer discarded because restoration is imperfect, and startup no longer displays an unregistered default shortcut as if it were active. The exact package and DMG pass local verification. A packaged frontend-to-Rust IPC contract remains the next evidence slice; physical interaction and Apple release gates remain external.

## Sprint S83-packaged-runtime-contract-ipc — 2026-08-30

- [x] Trace the packaged runtime-contract timeout to the first missing command boundary.
- [x] Confirm the Tauri Rust-to-JavaScript argument casing contract from the command signature and the failing report path.
- [x] Correct the report payload to camelCase and centralize it in a small frontend helper.
- [x] Add a focused regression test for the report payload shape.
- [x] Run 45 frontend tests, TypeScript/Vite build, 38 Rust tests, and Rust check.
- [x] Package/install the exact arm64 app and verify the installed bundle and exact DMG payload.
- [x] Run the packaged runtime contract and record PASS evidence.
- [ ] Complete Accessibility-enabled physical area selection, Copy/Save, shortcut, Finder-drag, secondary-display, and Developer ID/notarization acceptance.

### Review

S83 fixed a real packaged IPC defect. The Rust handler was never entered because `App.tsx` sent snake_case keys while Tauri's JavaScript boundary expected camelCase; the catch path swallowed the rejected report call, so the verifier timed out despite native capture completing. The corrected exact package now produces `Result: PASS` with frontend readiness, successful capture IPC, matching `32×24` preview/backend dimensions, restored window, and released capture activity. Reports are `artifacts/tauri-e2e/s83-runtime-contract-final.txt`, `artifacts/tauri-e2e/s83-final-installed-verification.txt`, and `artifacts/tauri-e2e/s83-final-dmg-verification.txt`.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; two read-only subagent audits and a manual diff scan were completed. Simplify skipped because the code change is a focused payload-boundary fix.

## Sprint S84-native-capture-lifecycle-hardening — 2026-08-30

- [x] Reproduce and characterize the two restoration-owner risk and synchronous blocking capture path from source and packaged logs.
- [x] Move area/window/fullscreen/repeat native capture behind `spawn_blocking` async Tauri commands.
- [x] Make Rust the single hide/restore owner and remove redundant frontend show/focus calls.
- [x] Track native restoration failures and surface them in capture status and runtime-contract evaluation.
- [x] Add focused lifecycle-state regression coverage.
- [x] Run 42 frontend tests, 39 Rust tests, TypeScript/Vite build, exact arm64 package/install, runtime contract, installed verification, and mounted-DMG verification.
- [ ] Run a real delayed physical selector acceptance with Accessibility/Screen Recording enabled and verify the WebView remains responsive throughout.
- [ ] Complete physical area selection, Copy/Save, shortcut, Finder-drag, secondary-display, Developer ID signing, Gatekeeper, and notarization acceptance.

### Review

S84 hardens the reported freeze path at the correct ownership boundary. Native capture now runs off the WebKit command path, Rust performs and reports restoration, and React no longer performs a competing second restore. The exact package produces a passing runtime report with matching preview/backend dimensions and released activity; installed and mounted-DMG structural/helper checks also pass. A delayed physical selector is still required to prove real-world WebView responsiveness, and the local artifact remains ad-hoc.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; two focused read-only subagent audits and a manual diff scan were completed. Simplify skipped because the change is a bounded lifecycle refactor with direct ownership semantics.

## Sprint S85-lifecycle-evidence-hardening — 2026-08-30

- [x] Audit the runtime trace for stale events and missing restore visibility.
- [x] Clear the derived trace at the start of each packaged runtime-contract run.
- [x] Add explicit native restoration start, complete, and failure trace events.
- [x] Run frontend/Rust tests, builds, shell checks, exact package/install, runtime contract, installed verification, and mounted-DMG verification.
- [ ] Add delayed real-selector acceptance with Accessibility and Screen Recording enabled.
- [ ] Complete physical area selection, Copy/Save, shortcut, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S85 improves failure diagnosability without changing the capture adapter: every packaged runtime run now starts from a clean trace and records the native restoration outcome explicitly. The final trace shows one readiness cycle, native hide, restore start/complete, capture completion, and report entry. Local package evidence is green; real desktop interaction and Apple release trust remain external gates.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; one focused read-only subagent audit and a manual diff scan were completed. Simplify skipped because the source change is a small evidence hardening.

## Sprint S86-revision-stable-crop-boundary — 2026-08-30

- [x] Confirm the existing image-edit revision counter invalidates Reset and annotation mutations synchronously.
- [x] Add a focused failing test for delayed crop work that resolves after Reset or annotation mutation.
- [x] Extract and use a revision-stable async crop helper in the production crop pipeline.
- [x] Run focused RED/GREEN tests, full frontend suite, TypeScript/Vite build, Rust tests/check, exact arm64 package/install, runtime contract, installed verification, and mounted-DMG verification.
- [x] Refresh the canonical arm64 DMG artifact and confirm byte/hash parity with the packaged DMG.
- [ ] Add a component-level React harness for deferred browser image/canvas work and visible state commits.
- [ ] Complete physical selector, Copy/Save, shortcut, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S86 closes the testable portion of the remaining async-crop evidence gap. `resolveAtStableRevision` is used by the real crop rasterization path, returns the rendered result only when the image-edit revision is unchanged, and turns delayed Crop → Reset or Crop → annotation work into an explicit no-op. RED proof showed the new tests failed before the helper existed; GREEN verification then passed 45 frontend tests. The exact arm64 package was installed at `/Applications/ShotEye.app`, the packaged runtime contract passed, and the exact mounted DMG passed helper/identity/architecture/parity checks. A component-level React harness and all physical/Apple release gates remain open.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; two focused read-only subagent audits and a manual diff scan were completed. Simplify skipped because the code change is a small, single-purpose revision-boundary extraction.

## Sprint S87-packaged-react-crop-lifecycle — 2026-08-30

- [x] Confirm the project did not already declare a reproducible DOM/component test runtime.
- [x] Add project-local React Testing Library and jsdom dev dependencies.
- [x] Add a Tauri-boundary-mocked App harness that drives Paste → Crop pointer selection with deferred browser image loading.
- [x] Prove Crop → Reset and Crop → annotation interleavings preserve the newer visible image, status, and annotation count.
- [x] Run the focused harness, full 47-test frontend suite, TypeScript/Vite build, 39 Rust tests/check, exact arm64 package/install, runtime contract, installed verification, and mounted-DMG verification.
- [x] Refresh the canonical arm64 DMG and confirm byte/hash parity.
- [ ] Complete physical selector, Copy/Save, shortcut, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S87 closes the component-level async crop evidence gap without weakening the native boundary: only Tauri commands and native dialogs are mocked, while `App` receives real DOM renders and pointer events. The harness caught and fixed its own cleanup-isolation issue, then passed both interleavings. The exact arm64 app was packaged and installed at `/Applications/ShotEye.app`; the runtime contract, native helper self-tests, strict installed verification, and exact DMG payload verification passed. The package remains local ad-hoc signed, and physical macOS acceptance plus Apple distribution trust remain open.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; a focused package audit, the prior crop-flow audit, and a manual diff scan were completed. Simplify skipped because the test harness is a bounded verification-only addition.

## Sprint S88-packaged-react-capture-lifecycle — 2026-08-30

- [x] Add App-level success coverage for the Capture area action and valid native preview commit.
- [x] Prove a second Capture area request cannot overlap the first pending native operation.
- [x] Prove rejected capture and native cancellation results restore an actionable editor state.
- [x] Run the focused capture harness, full 51-test frontend suite, TypeScript/Vite build, 39 Rust tests/check, exact arm64 package/install, runtime contract, installed verification, and mounted-DMG verification.
- [x] Refresh the canonical arm64 DMG and confirm byte/hash parity.
- [ ] Complete physical selector, Copy/Save, shortcut, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S88 closes the component-level capture-entry evidence gap without changing the native capture implementation. The real `App` component now has deterministic coverage for the pending selecting state, single-flight guard, successful valid PNG commit, rejected capture, and native cancellation. The latest frontend suite passes 51 tests across 14 files; Rust passes 39 unit tests and `cargo check`; the exact arm64 app was packaged, installed at `/Applications/ShotEye.app`, runtime-contract verified, and checked again from the mounted DMG. The package remains ad-hoc signed, so physical macOS interaction and Apple distribution trust remain open.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; two focused read-only subagent audits and a manual diff scan were used. Simplify skipped because this is a bounded verification-only harness addition.

## Sprint S89-packaged-react-annotated-export — 2026-08-30

- [x] Add App-level annotated Copy coverage and assert canvas rasterization before the native adapter call.
- [x] Add App-level Save coverage and prove preparation starts after the user-selected destination is returned.
- [x] Add App-level Drag coverage and prove background prewarming does not bypass the shared annotated export path.
- [x] Correct the harness to use the actual accessible Drag control name and keep export mocks isolated between tests.
- [x] Run the focused 9-test harness, full 54-test frontend suite, TypeScript/Vite build, 39 Rust tests/check, exact arm64 package/install, runtime contract, installed verification, and mounted-DMG verification.
- [x] Refresh the canonical arm64 DMG and confirm byte/hash parity.
- [ ] Complete physical Clipboard, Save-dialog, Finder-drag, selector, shortcut, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S89 closes the component-level annotated export evidence gap without changing production export code. The real `App` harness now drives Rectangle annotation creation followed by Copy, Save, and Drag, holds deferred browser image loading, observes `strokeRect` rasterization, and verifies Save destination ordering. The focused harness passes 9/9 and the full frontend suite passes 54/54 across 14 files; Rust passes 39 tests and `cargo check`; the exact arm64 app was packaged, installed at `/Applications/ShotEye.app`, runtime-contract verified, and checked from the mounted DMG. The package remains ad-hoc signed, so physical interaction and Apple distribution trust remain open.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; one focused read-only subagent audit was attempted and the harness was manually reviewed. Simplify skipped because this is a bounded verification-only harness addition.

## Sprint S90-stable-local-package-identity — 2026-08-30

- [x] Re-audit the canonical checkout, branch parity, existing WIP, package script, local identity, and S89 evidence before editing.
- [x] Add a bounded non-interactive probe for `ShotEye Local Development` and preserve explicit ad-hoc fallback when the private key cannot be used.
- [x] Sign the bundled selector first, then re-sign the containing app so local app/helper authorities match.
- [x] Run the full 54-test frontend suite, 39 Rust tests, `cargo check`, shell syntax checks, and `git diff --check`.
- [x] Package the exact arm64 app, install it at `/Applications/ShotEye.app`, run the runtime contract, verify the installed bundle, and verify the mounted DMG.
- [x] Copy the final DMG to `artifacts/releases/ShotEye_0.1.0_aarch64.dmg` and confirm byte/hash parity.
- [x] Record the S90 contract and evidence paths in PRD/spec/task trackers and lessons.
- [ ] Obtain Developer ID credentials and complete physical Screen Recording, selector drag, shortcut, Clipboard/Save, Finder-drag, secondary-display, Gatekeeper, and notarization acceptance.

### Review

S90 fixes the local package identity problem that caused repeated TCC reauthorization across ad-hoc rebuilds when a usable local certificate is available. The package script probes private-key access without hanging, configures Tauri with the stable identity, then repairs the nested selector signature before re-signing the outer app. The final installed app and mounted DMG report the same local authority for the app and helper and pass all structural/runtime checks.

Verification: frontend 54/54, Rust 39/39, `cargo check`, shell syntax, `git diff --check`, stable-identity arm64 package, exact install, packaged runtime contract, installed verifier, and mounted-DMG verifier. `spctl`/Developer ID/notarization and physical UI acceptance remain unproven external gates.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; bounded read-only subagent audits were dispatched but did not return before timeout, so the final manual diff scan and package/verifier evidence are recorded instead. Simplify skipped because the behavior-bearing change is a single guarded packaging path with no duplicated production logic to extract.

## Sprint S91-capture-mode-entry-evidence — 2026-08-30

- [x] Audit the current capture toolbar and identify the untested Window, Full screen, and Repeat entry points.
- [x] Extend the real `App` harness through all three controls and assert command routing, preview commit, status, and re-enabled controls.
- [x] Update README package/verification examples and stable-signing guidance.
- [x] Run the focused 12-test harness and complete the final full frontend suite.
- [ ] Complete physical selector, shortcut, Clipboard/Save, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S91 closes an evidence gap in the user-visible capture surface: area capture was covered, but Window, Full screen, and Repeat could have drifted without a component-level regression. The new tests exercise the same `App` lifecycle and native boundary used in production, while keeping physical desktop claims separate. README guidance now matches the stable local signing behavior introduced in S90.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; bounded read-only audits were dispatched but did not return before timeout, so the changed test/documentation files received a manual focused scan. Simplify skipped because the change is a small additive test matrix and documentation correction.

## Sprint S92-startup-readiness-and-dmg-provenance — 2026-08-30

- [x] Confirm the queued global-shortcut readiness race with a deferred-listener RED test.
- [x] Make runtime-contract startup await listener registration and retain one readiness signal; focused App harness passes 13/13.
- [x] Atomically refresh the canonical architecture-specific DMG from package output and enforce byte parity in package/verification paths.
- [x] Run full frontend 58/58, Rust 39/39, `cargo check`, production build, shell syntax, and `git diff --check`.
- [x] Rebuild/install the exact arm64 package and pass runtime, installed, and mounted-DMG verification.
- [x] Prove a deliberately mutated DMG is rejected before mounting, then clean the temporary fixture.
- [ ] Complete physical selector, shortcut, Clipboard/Save, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S92 closes two release-quality gaps found by independent bounded audits: startup readiness could consume a queued event before the WebView listener existed, and the canonical download artifact was only manually compared. The fix preserves one listener/readiness owner and makes package output the source for an atomic canonical-DMG refresh, with verification rejecting mismatches before any mounted-payload checks.

Verification: frontend 58/58, Rust 39/39, `cargo check`, production build, shell syntax, `git diff --check`, stable-identity package/install, runtime contract, installed verifier, mounted-DMG verifier, canonical parity, and negative mismatch rejection. Public Apple trust and physical UI acceptance remain external.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the packaging and startup audits were dispatched as bounded subagents, one returned the startup finding and the other returned the DMG finding, and the final diff was manually scanned. Simplify skipped because the changes are narrow guards around existing lifecycle/package boundaries.

## Sprint S93-session-capture-history — 2026-08-30

- [x] Audit the current canonical image writers and choose a bounded session-only history model.
- [x] Add immutable history helper with retention and duplicate-id tests.
- [x] Add Recent captures restore controls and reset the restored editor source state coherently.
- [x] Drive Paste → Capture → Restore through the real App harness; focused harness passes 14/14.
- [x] Run full frontend 63/63 across 15 files, Rust 39/39, `cargo check`, production build, and `git diff --check`.
- [x] Package/install exact arm64 app, run runtime-contract, installed-bundle, mounted-DMG, and canonical parity checks.
- [ ] Complete physical selector, shortcut, Clipboard/Save, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.
- [ ] Decide whether durable capture history belongs in a later privacy-reviewed sprint.

### Review

S93 adds a small session-only memory surface around the existing canonical image result path. Successful captures and imports become restorable without introducing disk persistence, permissions, or another native storage boundary. Restore uses the existing exclusive operation lane and clears editing state so a prior source cannot inherit annotations from the newer image.

Verification: focused App harness 14/14, full frontend 63/63 across 15 files, Rust 39/39, `cargo check`, production build, shell syntax, `git diff --check`, stable-identity package/install, runtime contract, installed verifier, mounted-DMG verifier, and canonical DMG byte parity.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; a bounded history audit was attempted but did not return before the timeout, so the helper/App diff was manually scanned and covered by focused tests. Simplify skipped because the implementation is already a narrow helper plus one existing App state path.

## Sprint S95-session-history-memory-bound — 2026-08-30

- [x] Confirm session history is the correct canonical successful-image boundary.
- [x] Add a 128 MiB encoded-data budget in addition to the eight-entry limit.
- [x] Add deterministic budget-eviction regression coverage.
- [x] Run focused history 5/5 and full frontend 64/64 across 15 files.
- [x] Run Rust 39/39, `cargo check`, production build, stable-identity package/install, runtime, installed, mounted-DMG, and canonical parity verification.
- [ ] Install the missing `rustfmt` and `clippy` toolchain components and rerun those checks.
- [ ] Complete physical selector, shortcut, Clipboard/Save, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S95 closes a memory-safety gap in the session history without adding disk persistence or a new privacy boundary. It keeps the newest capture available while evicting older entries once the base64-backed data URL budget is reached.

Verification: focused history 5/5, full frontend 64/64 across 15 files, Rust 39/39, `cargo check`, production build, shell/package verification, exact arm64 install, runtime contract, installed verifier, mounted-DMG verifier, and canonical DMG byte parity.

`cargo fmt --check` and `cargo clippy --lib --all-targets` were attempted but could not run because those components are not installed for the active stable toolchain.

## Sprint S96-native-lint-cleanup — 2026-08-30

- [x] Install the Rust `rustfmt` and `clippy` components for the active stable toolchain.
- [x] Fix six available native Clippy warnings with narrow changes at existing IPC/native boundaries.
- [x] Verify `cargo clippy --lib --all-targets` is clean.
- [x] Re-run frontend 64/64, Rust 39/39, `cargo check`, production build, package/install, runtime, installed, mounted-DMG, and canonical parity checks.
- [ ] Resolve repository-wide `cargo fmt --check` drift in a separately scoped formatting sprint.
- [ ] Complete physical selector, shortcut, Clipboard/Save, Finder-drag, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S96 improves native code quality without changing the capture contract. The fix set is limited to Clippy-backed parameter/style corrections and an explicit allowance documenting why the Tauri runtime-contract handler intentionally mirrors its IPC fields.

Verification: Clippy clean, frontend 64/64 across 15 files, Rust 39/39, `cargo check`, production build, stable-identity package/install, runtime contract, installed verifier, mounted-DMG verifier, and canonical DMG byte parity.

`cargo fmt --check` remains red because the existing Rust WIP is not formatter-clean across `src-tauri/src/lib.rs` and `macos_drag.rs`; no broad formatting rewrite was made.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the subagent audits did not return before timeout, so the narrow Rust diff was manually scanned and validated by Clippy, tests, and package verification. Simplify skipped because the changes are direct lint corrections with no duplicated behavior to extract.

## Sprint S97-privacy-safe-redaction — 2026-08-30

- [x] Add Redact to the annotation model and tool palette.
- [x] Support source-coordinate hit-testing, move, resize, and meaningful-size validation for Redact.
- [x] Render Redact as an opaque black fill in the live editor and raster export compositor.
- [x] Cover Redact geometry, renderer fill coordinates, and real App Copy flow; focused 22/22.
- [x] Run full frontend 67/67 across 15 files, Rust 39/39, `cargo check`, and Clippy clean.
- [x] Rebuild/install exact arm64 app and pass runtime, installed-bundle, mounted-DMG, and canonical parity verification.
- [ ] Complete physical pointer redaction, Clipboard/Save/Finder, secondary-display, Developer ID, Gatekeeper, and notarization acceptance.

### Review

S97 adds privacy-safe redaction through the existing annotation/export boundary. The source image remains intact for Reset, while every composed output receives an opaque black fill, avoiding a privacy feature that only looks masked in the WebView.

Verification: focused Redact geometry/renderer/App 22/22, full frontend 67/67 across 15 files, Rust 39/39, `cargo check`, Clippy clean, production build, exact arm64 package/install, runtime contract, installed verifier, mounted-DMG verifier, and canonical DMG byte parity.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; bounded subagent audits did not return before timeout, so the narrow annotation/App diff was manually scanned and covered by focused/full tests plus package verification. Simplify skipped because Redact reuses the existing annotation union and renderer boundary without duplicated export paths.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the subagent audits did not return before timeout, so the small helper diff was manually scanned and covered by focused/full tests. Simplify skipped because the implementation is a narrow extension of the existing immutable helper.

## Sprint S98-session-history-privacy-control — 2026-08-30

- [x] Add an accessible Clear history action to the Recent captures UI.
- [x] Preserve the current editor image while clearing every in-memory history entry.
- [x] Keep Clear history disabled during capture and publish an explicit status after clearing.
- [x] Add real App regression coverage; focused App 16/16 and combined Redact/App focused coverage 22/22.
- [x] Run full frontend 68/68 across 15 files, Rust 39/39, `cargo check`, and Clippy clean.
- [x] Rebuild/install exact arm64 app and pass runtime-contract, installed-bundle, mounted-DMG, and canonical parity verification.
- [ ] Complete physical pointer/shortcut/Clipboard/Save/Finder-drag/secondary-display acceptance and public Developer ID/Gatekeeper/notarization release gates.

### Review

S98 adds a narrow session-privacy control without introducing persistence. Clear history forgets the in-memory restore list but intentionally leaves the current canonical image visible so a user does not lose the work currently in the editor.

Verification: focused App 16/16, combined Redact/App focused 22/22, full frontend 68/68 across 15 files, Rust 39/39, `cargo check`, Clippy clean, production build, exact arm64 package/install, packaged runtime contract, installed verification, mounted-DMG verification, canonical DMG parity, and the expected local-only `--release` rejection.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the bounded subagent audits did not return before timeout, so the small App/CSS/test diff was manually scanned and covered by focused/full tests plus package verification. Simplify skipped because the control reuses the existing session-state boundary without duplicated behavior.

## Sprint S99-permission-denial-before-hide — 2026-08-30

- [x] Audit the reported repeated-permission path and identify the hide-before-preflight ordering.
- [x] Move parent Screen Recording preflight before hiding the editor, without weakening the non-prompting guard.
- [x] Preserve runtime-contract lifecycle coverage and capture activity cleanup.
- [x] Add the focused Rust ordering regression; focused 1/1.
- [x] Run frontend 68/68 across 15 files, Rust 40/40, `cargo check`, and Clippy clean.
- [x] Rebuild/install the exact arm64 package and pass runtime-contract, installed-bundle, mounted-DMG, and canonical parity verification.
- [x] Confirm `verify_app.sh --release` still fails closed for the local-only signer; record the expected rejection in `artifacts/tauri-e2e/s100-release-rejection.txt`.
- [ ] Complete physical denied-permission UI, selector/shortcut/export/secondary-display acceptance, and Developer ID/Gatekeeper/notarization release gates.

### Review

S99 removes an unnecessary lifecycle transition from a known permission-denied path. ShotEye now keeps the editor available while presenting the existing actionable guidance; it still never requests consent from a normal capture action.

Verification: focused Rust 1/1, full frontend 68/68, Rust 40/40, `cargo check`, Clippy clean, production build, exact arm64 package/install, packaged runtime contract, installed verification, mounted-DMG verification, canonical DMG parity, and the expected local-only `--release` rejection.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the narrow Rust diff was manually scanned and covered by the focused/full native checks and packaged verification. Simplify skipped because the change is a single ordering guard with no duplicated behavior to extract.

## Sprint S100-focus-driven-permission-refresh — 2026-08-30

- [x] Audit the startup-only Screen Recording status path and identify the missing post-Settings refresh.
- [x] Register a consent-free Tauri window-focus listener that refreshes status only when ShotEye becomes focused.
- [x] Skip refresh while a native operation owns the exclusive lane and guard delayed results with the status epoch.
- [x] Add App-level regression coverage for focus refresh and blur suppression; focused App 17/17.
- [x] Run full frontend 69/69 across 15 files, Rust 40/40, `cargo check`, and Clippy clean.
- [x] Rebuild/install the exact arm64 package and pass runtime-contract, installed-bundle, mounted-DMG, and canonical parity verification.
- [ ] Complete physical denied-permission UI, selector/shortcut/export/secondary-display acceptance, and Developer ID/Gatekeeper/notarization release gates.

### Review

S100 closes the user-facing status gap after the operator enables ShotEye in macOS Privacy & Security and returns to the editor. The background refresh never requests consent and remains separate from the explicit Permissions action.

Verification: focused App 17/17, full frontend 69/69 across 15 files, Rust 40/40, `cargo check`, Clippy clean, production build, exact arm64 package/install, packaged runtime contract, installed verification, mounted-DMG verification, and canonical DMG parity.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the bounded read-only subagent audit timed out before returning, so the narrow App/test diff was manually scanned and covered by focused/full tests plus package verification. Simplify skipped because the listener reuses the existing status epoch and native-operation boundary without duplicated behavior.

## Sprint S102-package-refresh — 2026-08-30

- [x] Rebuild the current source with the stable local signing identity.
- [x] Install the exact arm64 bundle at `/Applications/ShotEye.app`.
- [x] Verify the installed package and mounted canonical DMG, retaining `artifacts/tauri-e2e/s102-final-installed-verification.txt` and `artifacts/tauri-e2e/s102-final-dmg-verification.txt`.
- [x] Confirm canonical/build DMG byte parity and stable app/helper authority.
- [ ] Unlock the desktop and grant Accessibility before physical UI acceptance.
- [ ] Obtain Developer ID credentials and notarization access before public release.

## Sprint S103-accessibility-ui-smoke — 2026-08-30

- [x] Add `scripts/verify_ui_smoke.sh` for the exact `/Applications/ShotEye.app` bundle.
- [x] Enforce strict signature validation and exactly one canonical `shoteye` process.
- [x] Check accessible product toolbar controls and native `ShotEye`, `File`, `Capture`, `Edit`, and `Help` menus.
- [x] Fail closed with `Result: BLOCKED` and exit `2` when Accessibility or an unlocked desktop is unavailable.
- [x] Run shell syntax and blocked-state verification; retain `artifacts/tauri-e2e/s103-physical-ui-smoke.txt` and `artifacts/tauri-e2e/s103-ui-smoke-command.txt`.
- [ ] Re-run the harness from an unlocked desktop with Accessibility enabled, then complete physical selector, shortcut, export, and secondary-display acceptance.

### Review

S103 adds release-quality evidence plumbing only; it does not claim physical interaction from the current locked/Accessibility-denied host. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. Simplify skipped because the harness is a single-purpose shell/AppleScript boundary.

## Sprint S105-representative-toolbar-clicks — 2026-08-30

- [x] Extend the canonical UI harness with reversible `Rectangle`, `Select`, `Pin ShotEye`, and `Unpin ShotEye` clicks.
- [x] Keep the harness non-destructive and separate from capture, permission, dialog, clipboard, and file-write actions.
- [x] Run shell syntax and blocked-state verification; current host returns exit `2` with a `Result: BLOCKED` report because Accessibility is denied.
- [ ] Re-run the click phase from an unlocked desktop with Accessibility enabled.

### Review

S105 directly targets the prior non-clickable-icon report, but the click assertions remain unexecuted until the macOS Accessibility prerequisite is available. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. Simplify skipped because the four actions are a narrow, explicit acceptance set.

## Sprint S106-single-flight-permission-refresh — 2026-08-30

- [x] Add a RED App regression for duplicate focus notifications during a pending permission-status IPC call.
- [x] Add the frontend in-flight guard and release it on every terminal promise path.
- [x] Verify focused App 19/19 and full frontend 71/71, including rejection-and-retry coverage.
- [x] Rebuild/install the fixed arm64 package and pass Rust 40/40, `cargo check`, Clippy, installed verification, mounted-DMG verification, and canonical parity.
- [x] Run the updated UI harness against the fixed package; record the environment prerequisite as `BLOCKED` with exit `2` and `-25211`.
- [ ] Re-run representative toolbar clicks from an unlocked desktop with Accessibility enabled.

### Review

S106 removes redundant focus-refresh IPC calls without changing the permission UX or capture lifecycle. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the focused regression was run red before the fix and green after it. Simplify skipped because the guard is a single local ref at the existing async boundary.

### Review

S102 refreshed package evidence only; no source code changed. Physical UI remains unverified because the desktop session is locked and Accessibility automation is denied.

## Sprint S101-packaged-baseline-audit — 2026-08-30

- [x] Sync `origin` before the audit and confirm the branch is neither behind nor ahead of `origin/main`.
- [x] Confirm the installed app/helper use the stable local `ShotEye Local Development` identity.
- [x] Run the exact installed arm64 package verifier and retain its report at `artifacts/tauri-e2e/s101-baseline-installed-verification.txt`.
- [x] Confirm helper Screen Recording preflight and Core Graphics display-read both return success.
- [x] Record the locked-session/Accessibility boundary at `artifacts/tauri-e2e/s101-physical-acceptance-boundary.txt`.
- [ ] Unlock the desktop and grant Accessibility before making physical toolbar, pointer, shortcut, Clipboard/Save/Finder-drag, or secondary-display claims.
- [ ] Obtain Developer ID credentials and notarization access for public release.

### Review

S101 found no reproducible packaged code failure and introduced no source changes. The next test must be run from an unlocked desktop with Accessibility enabled; local helper self-tests are not a substitute for that physical acceptance.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. The bounded read-only subagent audit timed out before returning; host verification remains authoritative.

## Sprint S107-packaged-selector-cancellation-harness — 2026-08-30

- [x] Audit the packaged selector's real process and Escape cancellation contract before changing the harness.
- [x] Add opt-in `--capture-cancel` coverage for `Capture area` → selector appears → Escape → selector exits → editor restores.
- [x] Keep the default UI smoke path non-destructive and fail closed on missing Accessibility, locked desktop, or Screen Recording preflight.
- [x] Run shell syntax and both blocked-state paths; retain `artifacts/tauri-e2e/s107-ui-smoke-command.txt` and `artifacts/tauri-e2e/s107-capture-cancel-command.txt`.
- [ ] Re-run the opt-in selector cancellation check from an unlocked desktop with Accessibility enabled, then complete physical drag, shortcut, export, and secondary-display acceptance.

### Review

S107 improves evidence coverage without changing capture production code. The initial bundle-identifier System Events lookup reproduced `-1728`; the harness now targets the actual `shoteye` executable process and the corrected path reproduces the expected `-25211` Accessibility boundary. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. The bounded read-only subagent audit did not return before its wait bound; host checks remain authoritative.

## Sprint S108-selector-permission-mismatch-hardening — 2026-08-30

- [x] Audit the parent/helper Screen Recording preflight and system fallback ordering against the repeated consent-prompt report.
- [x] Stop explicit helper denial before `/usr/sbin/screencapture`; retain fallback only for inconclusive probes and recoverable launch failures.
- [x] Add focused Rust coverage for denial mapping and no-repeat-prompt messaging; run 18 capture tests and 4 selector-dispatch tests.
- [x] Run the full frontend suite (71/71), TypeScript build, Rust check, Clippy, package/install, runtime contract, installed verification, mounted-DMG verification, and helper self-tests.
- [x] Record normal and opt-in Accessibility smoke as `BLOCKED` with `-25211`, without claiming physical capture success.
- [ ] Validate the fixed package on an unlocked Accessibility-enabled desktop, including an intentional helper TCC mismatch and subsequent successful area capture.

### Review

S108 fixes the prompt-loop root cause at the native dispatch boundary and leaves the UI unchanged because the current source has no duplicate traffic-light markup; the duplicated-chrome screenshot is treated as evidence from an older/stale package until reproduced against the current install. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. The initial full check caught and removed one obsolete dead helper after the dispatch contract changed.

## Sprint S109-parent-helper-permission-diagnostics — 2026-08-30

- [x] Extend the non-prompting permission status command to probe the exact bundled selector on a worker thread.
- [x] Add distinct parent-denied, helper-mismatch, helper-inconclusive, and fully-available status messages with focused Rust coverage.
- [x] Run frontend 71/71, Rust 42/42, TypeScript build, cargo check, Clippy, package/install, runtime, installed, mounted-DMG, helper, and one-process checks.
- [x] Confirm the new diagnostic strings are embedded in `/Applications/ShotEye.app/Contents/MacOS/shoteye`.
- [x] Record both normal and opt-in UI smoke as `BLOCKED` with `-25211`; no physical capture claim is made.
- [ ] Validate parent/helper TCC mismatch and recovery on an unlocked Accessibility-enabled desktop, then complete physical capture, export, and secondary-display acceptance.

### Review

S109 moves the bounded helper probe off the Tauri UI command thread and turns a hidden identity mismatch into explicit recovery guidance. A command-scope mistake initially ran `npm test` from the repository root; the corrected run from `tauri-app` passed. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S110-status-footer-recovery-ui — 2026-08-30

- [x] Audit the current source for duplicate titlebar/traffic-light markup and reproduce the reported status-overflow symptom.
- [x] Replace the fixed-height status grid row with an auto-growing responsive row that wraps long recovery messages safely.
- [x] Add a real App regression asserting the status footer's `role="status"` and `aria-live="polite"` contract.
- [x] Run focused App 20/20, full frontend 72/72, TypeScript/Vite build, Rust 42/42, `cargo check`, and Clippy.
- [x] Rebuild/install the exact arm64 package and pass packaged runtime, installed, mounted-DMG, helper, and canonical parity verification.
- [x] Run normal and opt-in physical UI smoke; retain explicit `BLOCKED` reports with Accessibility error `-25211`.
- [ ] Re-run physical toolbar/capture/export/secondary-display acceptance on an unlocked desktop with Accessibility enabled.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S110 is locally verified and packaged, but physical macOS interaction is still environment-blocked. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S111-finder-image-drop-import — 2026-08-30

- [x] Add typed image-only Tauri file-drop parsing with malformed-payload rejection.
- [x] Route the first supported Finder drop through the guarded canonical `open_image` import path.
- [x] Show and clear a supported-image drop affordance across enter, leave, drop, and component disposal.
- [x] Add helper 10/10 and real App 21/21 coverage; run the full frontend suite at 83/83.
- [x] Run TypeScript/Vite, Rust 42/42, Cargo check, Clippy, package/install, runtime, installed, mounted-DMG, and canonical parity verification.
- [ ] Complete physical Finder drop and remaining Accessibility-enabled toolbar/capture/export/secondary-display acceptance.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S111 is locally verified and packaged. Physical Finder interaction remains an external acceptance gate because the current host denies Accessibility with `-25211`. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S112-privacy-safe-pixelate-annotation — 2026-08-30

- [x] Add Pixelate to the source-coordinate annotation model and rectangle-like editing rules.
- [x] Rasterize Pixelate by source-color blocks before Copy, Save, Drag, and Crop; fail closed to opaque black when pixel reads are unavailable.
- [x] Add a visible Pixelate editor preview and real App coverage for Pixelate → annotated Copy.
- [x] Run focused annotation/App 32/32, full frontend 87/87, TypeScript/Vite build, Rust 42/42, `cargo check`, and Clippy.
- [x] Rebuild/install the exact arm64 package and pass packaged runtime, installed, mounted-DMG, and canonical parity verification.
- [ ] Complete physical Pixelate/toolbar/selector/shortcut/Clipboard/Save/Finder-drop/secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S112 is locally verified and packaged. A test-fixture gap was fixed after the first App export regression exposed that the mock canvas did not provide the production context back-reference. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S113-privacy-safe-blur-annotation — 2026-08-30

- [x] Add Blur to the source-coordinate annotation model and rectangle-like editing rules.
- [x] Rasterize Blur with a bounded separable blur before Copy, Save, Drag, and Crop; fail closed to opaque black when pixel reads are unavailable.
- [x] Add a clipped live Blur editor preview and real App coverage for Blur → annotated Copy.
- [x] Extend the Accessibility smoke inventory for Pixelate and Blur and run shell syntax validation.
- [x] Run focused annotation/App 36/36, full frontend 91/91, TypeScript/Vite build, Rust 42/42, `cargo check`, and Clippy.
- [x] Rebuild/install the exact arm64 package and pass packaged runtime, installed, mounted-DMG, and canonical parity verification.
- [ ] Complete physical Blur/Pixelate/toolbar/selector/shortcut/Clipboard/Save/Finder-drop/secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S113 is locally verified and packaged. The UI smoke report remains an explicit Accessibility block (`-25211`), not a physical interaction claim. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S114-native-tools-menu — 2026-08-30

- [x] Add the native Tools menu with all supported editor tools.
- [x] Route native Tools callbacks through the current React tool-selection dispatcher and preserve capture-active protection.
- [x] Add menu-model and real App coverage for native Tools routing.
- [x] Run focused menu/App 26/26, full frontend 92/92, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, and shell syntax validation.
- [x] Rebuild/install the exact arm64 package and pass packaged runtime, installed, mounted-DMG, and canonical parity verification.
- [ ] Complete physical Tools-menu/toolbar/selector/shortcut/Clipboard/Save/Finder-drop/secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S114 is locally verified and packaged. The UI smoke report remains an explicit Accessibility block (`-25211`), not a physical interaction claim. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S115-repeat-capture-keyboard-shortcut — 2026-08-30

- [x] Map `⌘⇧R`/`⌃⇧R` to Repeat Last Capture in the shared editor shortcut dispatcher.
- [x] Route the keyboard action through the existing guarded repeat-capture lifecycle.
- [x] Add focused helper and real App keyboard-event coverage.
- [x] Run focused shortcut/App 30/30, full frontend 94/94, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, and package checks.
- [x] Rebuild/install the exact arm64 package and pass runtime, installed, mounted-DMG, and canonical parity verification.
- [ ] Complete physical shortcut invocation and remaining selector/toolbar/menu/Clipboard/Save/Finder-drop/secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S115 is locally verified and packaged. The UI smoke report remains an explicit Accessibility block (`-25211`), not a physical interaction claim. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S116-repeat-shortcut-discoverability — 2026-08-30

- [x] Add a visible `⌘⇧R` hint, tooltip, and `aria-keyshortcuts` metadata to the Repeat Last Capture toolbar control.
- [x] Advertise `CmdOrCtrl+Shift+R` on the native Capture menu item without creating a second repeat action path.
- [x] Add focused menu-model and real App metadata coverage; focused menu/App 28/28 and full frontend 95/95 pass.
- [x] Rebuild/install the exact arm64 package and pass runtime, installed, and mounted-DMG verification.
- [ ] Complete physical shortcut/menu/toolbar/selector/Clipboard/Save/Finder-drop/secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S116 is locally verified and packaged. The UI smoke report remains an explicit Accessibility block (`-25211`), not a physical interaction claim. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S117-canonical-repeat-shortcut — 2026-08-30

- [x] Define one canonical Repeat Last Capture registration string.
- [x] Derive native-menu, display, and ARIA shortcut representations from the canonical value.
- [x] Add focused shortcut-display contract coverage; focused shortcut/menu/App 33/33 and full frontend 96/96 pass.
- [x] Rebuild/install the exact arm64 package and pass runtime, installed, and mounted-DMG verification.
- [ ] Complete physical shortcut/menu/toolbar/selector/Clipboard/Save/Finder-drop/secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S117 is locally verified and packaged. The UI smoke report remains an explicit Accessibility block (`-25211`), not a physical interaction claim. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S118-primary-toolbar-shortcuts — 2026-08-30

- [x] Add visible shortcut hints, tooltips, and `aria-keyshortcuts` metadata to Open, Paste, Copy, Save, Undo, Redo, and Repeat toolbar controls.
- [x] Centralize the primary shortcut contract and derive native-menu accelerators from it.
- [x] Add focused menu/shortcut/App coverage; focused 35/35 and full frontend 98/98 pass.
- [x] Rebuild/install the exact arm64 package and pass runtime, installed, and mounted-DMG verification.
- [ ] Complete physical shortcut/menu/toolbar/selector/Clipboard/Save/Finder-drop/secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run release-mode Gatekeeper/notarization verification.

### Review

S118 is locally verified and packaged. The UI smoke report remains an explicit Accessibility block (`-25211`), not a physical interaction claim. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S119-release-notarization-order — 2026-08-30

- [x] Add shared app/DMG notarization and stapling helpers.
- [x] Enforce app archive notarization, app stapling/validation, DMG creation, DMG notarization/stapling, and canonical-copy order.
- [x] Add a no-Apple-credentials release rejection test and a fake-`xcrun` ordering regression.
- [x] Rebuild/install the exact arm64 local package and pass runtime, installed, and mounted-DMG verification.
- [x] Record the intentional release-mode rejection and Accessibility-blocked physical smoke reports.
- [ ] Configure Developer ID credentials and run public release Gatekeeper/notarization verification.
- [ ] Complete physical selector, shortcut, toolbar, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop.

### Review

S119 is locally verified and packaged. The release pipeline now fails closed without a public signer; the physical UI report remains an explicit Accessibility block (`-25211`). Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S120-area-permission-identity — 2026-08-30

- [x] Reproduce and document the parent-denied/selector-granted permission matrix.
- [x] Add a failing Rust regression for area capture using the authorized bundled selector.
- [x] Implement effective area permission handling without weakening explicit denial or inconclusive-probe safety.
- [x] Run focused Rust/frontend/build/package/runtime verification and record evidence.
- [x] Refresh PRD, spec, kanban, TODO, learnings, and lessons with the completed result.
- [ ] Complete physical selector, shortcut, toolbar, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- [ ] Configure Developer ID credentials and run public release Gatekeeper/notarization verification.

### Review

S120 is locally verified and packaged. The physical UI report remains an explicit Accessibility block (`-25211`), not a physical interaction claim. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S121-selector-aware-permission-recovery — 2026-08-30

- [x] Inspect the exact bundled selector before invoking the parent macOS permission request.
- [x] Return non-prompting guidance for selector-authorized, selector-denied, and selector-inconclusive states.
- [x] Add Rust permission-action matrix coverage.
- [x] Pass frontend 98/98, TypeScript/Vite build, Rust 45/45, `cargo check`, Clippy, shell syntax, package/install, runtime, installed-bundle, mounted-DMG, and release-rejection verification.
- [x] Record `artifacts/tauri-e2e/s121-runtime-contract.txt`, `artifacts/tauri-e2e/s121-final-installed-verification.txt`, and `artifacts/tauri-e2e/s121-final-dmg-verification.txt`.
- [ ] Complete physical selector/export acceptance on an unlocked, Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run public release verification.

### Review

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. Manual diff scan completed.

## Sprint S122-helper-output-boundary — 2026-08-30

- [x] Add a permission-free bundled-selector `--self-test-capture-output` path using the production compositor and PNG writer.
- [x] Validate written PNG signature, dimensions, nontransparent pixels, and deterministic seam/orientation colors.
- [x] Run the output self-test against the exact installed app and mounted canonical DMG and record hashes in the package reports.
- [x] Rebuild the arm64 package and pass runtime contract, package/install, mounted-DMG, shell syntax, and release-order checks.
- [ ] Complete physical selector/export/secondary-display acceptance on an unlocked, Accessibility-enabled desktop.
- [ ] Obtain Developer ID credentials and run public release verification.

### Review

S122 is a behavior-bearing native verification change with focused helper execution and a manual diff scan. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S135/S137-orientation-and-finder-drag-hardening — 2026-08-30

### Done

- [x] Verify a real one-display capture copied from the exact installed package is upright, non-empty, and `800×700` with a valid PNG signature.
- [x] Pass the originating WebView pointer coordinates through the Drag command and convert them safely for flipped/unflipped AppKit views.
- [x] Create the synthetic AppKit drag event in window-base coordinates rather than global screen coordinates.
- [x] Retain private Finder drag staging through asynchronous destination consumption; cleanup remains owned by managed Rust state at process teardown.
- [x] Rebuild/install the exact arm64 package and pass frontend 103/103, Rust 47/47, `cargo check`, package verification, orientation evidence, and isolated Finder drop.
- [x] Record `artifacts/tauri-e2e/s135-orientation-acceptance.txt`, `s135-current-orientation.png`, `s137-finder-drop-acceptance.txt`, `s137-finder-drop/ShotEye Capture.png`, and `s137-drag-lifecycle-installed.txt`.

### Pending external gates

- [ ] Test secondary-display capture with a physically attached second display.
- [ ] Test an occupied shortcut and an alternate keyboard layout.
- [ ] Obtain a real Developer ID Application identity and notarization credentials, then run release Gatekeeper/notarization verification.

### Review

S135/S137 are locally verified on the installed Apple Silicon package. Two failed Finder probes were diagnosed as harness conditions (no in-memory capture after reinstall; then Finder overlap) before the isolated passing run. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.
## Sprint S138-installed-save-acceptance — 2026-08-30

### Done

- [x] Fresh area capture and Save action completed on the exact installed package.
- [x] PNG header, size, dimensions (`1000×800`), SHA-256, strict signature, and one canonical process validated.
- [x] Open image exercised against the saved artifact; inaccessible WebView status prevents claiming pixel-equivalence.

### Pending external gates

- [ ] Secondary-display capture.
- [ ] Occupied shortcut and alternate keyboard layout.
- [ ] Developer ID Application identity and notarization credentials.
## Sprint S139-release-gate-audit — 2026-08-30

### Done

- [x] Ran release-mode verification against `/Applications/ShotEye.app`.
- [x] Confirmed the verifier rejects the local-only signing identity before public-release claims.

### Pending external gate

- [ ] Obtain Developer ID Application credentials and notarization credentials, then rerun release packaging and Gatekeeper verification.

## Sprint S148-repeatable-physical-area-capture — 2026-09-02

- [x] Consolidate the proven installed Capture Area toolbar → selector → HID drag → Copy clipboard sequence into `scripts/test_physical_area_capture.sh`.
- [x] Pass a fresh physical primary-display acceptance and validate a non-empty, upright `1000×800` PNG at `artifacts/tauri-e2e/s148-physical-area-copy.png`.
- [x] Pass the serial packaged selector-cancellation acceptance and local installed/DMG package verification.
- [x] Restrict physical output replacement to `artifacts/tauri-e2e` and pass two additional serial primary-display runs (`s149`, `s150`).
- [x] Re-run the shortcut-conflict harness serially; retain its explicit `BLOCKED` outcome because duplicate Carbon registration prevents proof of exclusive fixture ownership.
- [ ] Replace or augment the Carbon fixture with an exclusive external reservation boundary before claiming physical shortcut-conflict acceptance.
- [x] Audit the Tauri/global-hotkey macOS implementation; it also uses Carbon `RegisterEventHotKey`, so it cannot be substituted for an exclusive fixture.
- [ ] Complete secondary-display and Developer ID/Gatekeeper/notarization acceptance.

### Review

S148 is a reproducibility/evidence improvement, not a shortcut-conflict product claim. The physical capture script intentionally scopes its proof to the primary display and Copy output. Two concurrent UI harnesses were stopped as invalid before serial reruns; no selector remained and the canonical app recovered to one process.

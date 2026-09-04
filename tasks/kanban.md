# ShotEye Kanban

## Done

- Sprint S142-stable-accessibility: added direct AX attachment/surface discovery, reversible isolated shortcut-fixture cleanup, and fail-closed conflict acceptance. Direct AX smoke passed; the host's duplicate Carbon reservation behavior correctly blocked exclusive conflict proof. Evidence: `artifacts/tauri-e2e/s142-direct-ax-smoke.txt`, `artifacts/tauri-e2e/shortcut-conflict-fixture.txt`, `artifacts/tauri-e2e/shortcut-conflict-acceptance.txt`.
- Sprint S143-shortcut-transaction: extracted atomic shortcut replacement logic and added conflict/preserve, rollback, and accepted-replacement Rust tests. Focused native coverage passed 4/4; packaged OS conflict remains explicitly blocked by the non-exclusive Carbon fixture boundary.
- Sprint S146-bounded-accessibility: bounded packaged AppleScript automation and passed fresh direct-AX Capture Area cancellation with editor restoration and selector cleanup. Evidence: `artifacts/tauri-e2e/s146-capture-cancel-bounded.txt`.
- Sprint S147-physical-primary-capture: passed installed toolbar Capture Area through a real HID drag and Copy export. The resulting `1000×800` PNG is valid and upright. Evidence: `artifacts/tauri-e2e/s147-physical-area-copy.txt`.

- Sprint S1-editor-input: fixed inactive foreground editor activation.
- Sprint S1-editor-input: closed selection overlays before editor presentation.
- Sprint S1-editor-input: verified release build and strict signature.
- Capture, annotation, image import, clipboard, repeat capture, and configurable shortcut slices.
- Sprint S2-tauri-diagnostic: production Tauri package builds and all eight toolbar actions complete a WebKit-to-Rust interaction regression.
- Sprint S3-tauri-capture: native macOS capture command, preview, clipboard copy, and cancellation handling implemented.
- Sprint S6-tauri-lifecycle: single-instance focus behavior and global `⌘⇧Y` capture shortcut implemented and packaged.
- Sprint S7-tauri-canonical-capture: validated PNG bytes now live in Rust-owned state for Copy and Save.
- Sprint S8-tauri-annotation-export: image-coordinate Rectangle, Arrow, Text, and Draw overlays now compose into the canonical PNG only for Copy/Save; cancellation restores the packaged editor through its allowed window lifecycle.
- Sprint S9-tauri-image-import: Open PNG/JPEG/TIFF and Paste PNG/TIFF normalize to canonical PNG state; packaged Open JPEG → rectangle → Copy/Paste → Save regression passed.
- Sprint S18-native-titlebar-only: removed the duplicated WebView traffic lights; the packaged editor now relies exclusively on macOS's native close/minimize/zoom controls.
- Sprint S19-crop-reset-regression: Crop/Reset geometry has focused frontend coverage; the installed package passed JPEG open → Crop → Reset → Copy → valid saved PNG acceptance.
- S20-exact-build-permission-preflight: latest installed package safely reports unavailable Screen Recording access without re-prompting; physical capture waits for operator-approved TCC access.
- S21-annotation-undo-redo: packaged Rectangle → Undo → Redo acceptance passed with deterministic annotation history and focused frontend regression coverage.
- S22-native-shortcut-display: packaged toolbar and status use macOS shortcut notation (`⌘⇧Y`) with focused formatting coverage.
- S23-annotation-selection-delete: packaged Select → Delete → Undo passed with source-image hit testing and recoverable history.
- S24-annotation-move: packaged Select → drag-to-move → Undo passed.
- S25-local-workspace-rename: local workspace and isolated Git metadata renamed to `shoteye`; remote remains unchanged.
- S26-annotation-resize: packaged Select → handle drag → Undo acceptance passed for a rectangle; focused geometry tests pass.
- S27-native-appkit-selector: bundled AppKit area selector is packaged, resolved from the Tauri resource path, and the exact installed app passes launch plus permission-guard smoke checks.
- S28-editor-shortcuts: packaged `Cmd+Z`/`Cmd+Shift+Z` Undo/Redo acceptance passed; focused shortcut mapping coverage is green.
- S29-capture-reliability-hardening: selector key/deactivation cleanup, overlay exclusion, vertical multi-display transform, failure-state preservation, native PNG validation, helper fallback/error mapping, and Screen Capture usage metadata implemented and packaged.
- S29-capture-reliability-hardening follow-up: private capture temp directories are cleaned with RAII fallback, valid drag handoff is not mistaken for deactivation cancellation, and the exact installed helper matches the packaged helper.
- Sprint S30-window-capture: exposed native macOS window selection through the existing validated capture pipeline, with focused argument coverage and packaged installation.
- Sprint S31-permission-state: added a non-prompting startup Screen Recording check and surfaced its actionable state in the ShotEye editor.
- Sprint S32-pin-window: added a native always-on-top Pin toggle with explicit Tauri capability and failure-safe UI state.
- Sprint S33-private-clipboard-staging: removed predictable shared clipboard temp paths and added private cleanup coverage.
- Sprint S34-export-formats: added validated PNG/JPEG/TIFF Save output while preserving canonical PNG Copy behavior.
- Sprint S35-native-finder-drag: added a Cocoa/AppKit Finder-compatible Drag action backed by private managed PNG staging and main-thread native drag startup.
- Sprint S35-drag-review-hardening: fixed native event timing, added a visible drag image and session-end cleanup, and serialized revision-aware export preparation.
- Sprint S36-shoteye-product-path-and-capture-hardening: made Tauri the only root package/run path, isolated the legacy Swift prototype, hardened shortcut startup and recording, rejected partial display composites, and made delayed drag startup cancellation-safe.
- Sprint S37-product-status-surface: removed diagnostic tool acknowledgements and backend labels from the shipped editor so user-facing status remains deterministic.
- Sprint S38-native-executable-identity: renamed the native process to `shoteye` and made installed-bundle replacement remove stale framework binaries recoverably.
- Sprint S39-release-packaging-gate: added a credential-gated Developer ID/notarization package path with strict signature, Gatekeeper, and stapling checks.
- Sprint S40-helper-screen-recording-preflight: added a non-prompting helper TCC probe and avoided launching the bundled overlay when the helper cannot access display pixels.
- Sprint S41-startup-shortcut-recovery: cleared rejected persisted shortcut preferences at startup and preserved the active shortcut on explicit registration failures.
- Sprint S42-export-freshness-hardening: made Copy, Save, and Drag export preparation read the latest image/annotation refs and retry when the capture revision changes; 31 frontend tests, 24 Rust tests, arm64 packaging, exact install, strict signature, helper preflight, and PNG evidence passed.
- Sprint S43-installed-package-verification: added a single checked-in verifier for bundle identity, architecture, parity, strict signature, helper preflight, DMG presence, process count, and optional PNG evidence; the root launch verifier now delegates to it.
- Sprint S44-exclusive-export-actions: serialized user-triggered Copy, Save, and Drag through one release-safe async guard; 33 frontend tests, 24 Rust tests, arm64 packaging, exact install, verifier, and fresh PNG evidence passed.
- Sprint S45-unified-native-operation-lane: unified capture with Copy, Save, and Drag under one synchronous exclusive guard; focused/full frontend tests, Rust tests, arm64 package, exact install, verifier, and fresh PNG evidence passed.
- Sprint S46-native-menu-command-surface: added product-branded native File, Capture, Edit, and Help menus backed by current guarded React actions; focused menu-model tests, full frontend/Rust suites, arm64 package, exact install, and shared verifier passed.
- Sprint S47-transactional-display-selection: rejected display-gap rectangles before compositing, made helper launch fail closed on inconclusive probes, and added an installed geometry self-test; 35 frontend tests, 25 Rust tests, arm64 package, exact install, verifier, and PNG evidence passed.
- Sprint S48-bounded-native-capture-lifecycle: added owned child polling, timeout kill/reap, and no-fallback-on-timeout behavior; 35 frontend tests, 26 Rust tests, arm64 package, exact install, verifier, and PNG evidence passed.
- Sprint S49-status-and-package-evidence-hardening: guarded delayed startup statuses, removed background Drag writes to Rust state, bounded the helper permission probe, created DMGs directly with `hdiutil`, and verified the exact mounted DMG payload; 36 frontend tests, 27 Rust tests, arm64 package, exact install, and DMG payload verification passed.
- Sprint S100-focus-driven-permission-refresh: refreshes Screen Recording status after ShotEye regains focus without requesting consent, ignores blur, and protects late responses with the existing operation guard/status epoch; 69 frontend tests, 40 Rust tests/check, exact arm64 package/install, runtime contract, installed verification, mounted-DMG verification, and DMG hash parity pass; physical and public-release gates remain open.
- Sprint S101-packaged-baseline-audit: revalidated the stable local app/helper identity and exact installed arm64 package; helper permission/display-read and packaged verification pass, while physical UI acceptance is explicitly deferred because the desktop was locked and Accessibility automation was denied.
- Sprint S102-package-refresh: rebuilt, reinstalled, and reverified the current exact arm64 app and canonical DMG; local package gates pass, while physical interaction and public Apple release gates remain open.
- Sprint S103-accessibility-ui-smoke: added an independent canonical-package UI harness that checks one process, strict signature, accessible toolbar controls, and native menus; current host correctly reports `BLOCKED` because Accessibility is denied.
- Sprint S105-representative-toolbar-clicks: extended the harness with reversible Rectangle/Select/Pin/Unpin clicks; current host correctly stops at the Accessibility prerequisite and records `BLOCKED`.
- Sprint S106-single-flight-permission-refresh: coalesced duplicate pending focus status checks, with RED→GREEN App coverage and fixed-package verification; physical UI remains blocked by denied Accessibility.
- Sprint S50-mixed-DPI-compositor-evidence: added deterministic RGBA/nearest-neighbor composition and full-output native self-test coverage; installed app and exact DMG verification pass.
- Sprint S51-compositor-coordinate-hardening: replaced implicit integral rounding with explicit floor/ceil bounds and added vertical-band/fractional-edge full-pixel assertions; installed app and exact DMG verification pass.
- Sprint S52-capture-boundary-verification: added production crop-transform coverage and bounded Screen Recording settings recovery; installed app and exact DMG verification pass.
- Sprint S54-startup-shortcut-conflict-recovery: made default global-shortcut registration best-effort, tracked actual registration state, preserved atomic replacement, and verified the installed app plus mounted DMG.

## In progress

- Validate fresh-package foreground activation; automated startup evaluation now passes.
- Verify successful drag-selection through an independent desktop test harness.
- Re-enable Screen Recording for the latest installed Tauri ad-hoc signature and verify Full screen → Repeat Last Capture.
- S11-tauri-permission-preflight: packaged Capture area now returns an in-app unavailable-permission status without re-opening the system consent sheet.
- S11-tauri-permission-preflight: explicit Permissions request, Full screen, and Repeat Last Capture verified on the installed package after the current build was granted Screen Recording access.
- S14-shoteye-stable-local-signing: local certificate approach rejected after packaged control testing; strict signature verification was green but the certificate-signed WebKit editor was blank. The known-good ad-hoc app was restored. Developer ID remains required for a durable public-beta permission identity.
- S15-multidisplay-area-selector: area capture now explicitly starts macOS selection mode without main-display restrictions; focused regression and packaged UI guidance passed. Secondary-display physical drag remains pending hardware and exact-build permission authorization.
- S16-configurable-capture-shortcut: Rust safely replaces only registered shortcuts and the packaged editor exposes a persistent keyboard recorder. Manual modifier recording/global-invocation evidence remains pending because the accessibility harness cannot deliver a physical chord to the WebView control.
- S17-permission-recovery-control: the packaged editor now exposes a direct Screen Recording settings action separate from the explicit consent request; packaged strict signature and accessibility discovery passed.
- S13-shoteye-rename: user-facing window, menu, editor, bundle, and DMG branding renamed to ShotEye; re-authorizing the renamed ad-hoc build remains pending.
- Evaluate ScreenCaptureKit as a future pixel backend; the current bundled AppKit selector remains primary and `screencapture` remains fallback.
- S29 physical proof: exact-package Screen Recording authorization, successful area drag, Copy/Save, secondary-display capture, and Developer ID signing remain pending.
- S35 physical proof: drag the current annotated PNG into Finder and verify the dropped file; accessibility/device acceptance is still unavailable in this session.
- S36 physical proof: exact-package Screen Recording, secondary-display capture, shortcut recording, and Finder drop remain operator-gated acceptance work.
- S42 physical proof: independent rapid annotation/export UI acceptance and physical desktop drag-selection remain pending; this sprint proves the async revision boundary with focused tests and the installed package smoke gates.

## Done (continued)

- Sprint S61-frontend-capture-lifecycle: extracted the hidden-editor capture lifecycle into a focused TypeScript helper and covered success, hide failure, action failure, and restore failure paths. 41 frontend tests, 34 Rust tests, exact arm64 installation, strict signature checks, and mounted-DMG verification passed; physical desktop interaction and Developer ID/notarization remain open.
- Sprint S62-frontend-restoration-edge: added focused coverage proving `setFocus()` is still attempted when `show()` fails. 42 frontend tests, exact arm64 installation, strict signature checks, and mounted-DMG verification passed; physical desktop interaction and Developer ID/notarization remain open.
- Sprint S63-runtime-capture-evidence: exact helper permission/display-read checks and a real noninteractive system capture passed structurally (2940×1912 PNG), while the environment returned an all-black desktop image; interactive area selection and visible-pixel acceptance remain unproven.
- Sprint S64-native-selection-interaction: centralized AppKit drag state and normalization, reset stale undersized/cancelled gestures to idle, and added a permission-free selector self-test for valid/reversed/undersized/completed/cancelled gestures. Swift helper build, 42 frontend tests, 34 Rust tests, exact arm64 installation, strict signature checks, and mounted-DMG verification passed; physical pointer acceptance and Developer ID/notarization remain open.
- Sprint S65-atomic-export-write: Save now writes complete encoded output to a unique same-directory staging file, syncs it, and atomically replaces the destination; a Rust regression proves staging cleanup. Swift helper build, 42 frontend tests, 35 Rust tests, exact arm64 installation, strict signature checks, and mounted-DMG verification passed; physical Copy/Save interaction and Developer ID/notarization remain open.
- Sprint S66-packaged-interaction-evidence: fresh exact-package launch and second-launch single-instance checks passed, the ShotEye log audit found no app crash/panic, and the verified arm64 DMG was copied byte-for-byte to `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`; physical toolbar/drag/export acceptance and Developer ID/notarization remain open.
- Sprint S67-release-gate-audit: public packaging preflight correctly failed closed before building because no Developer ID signer is configured; the stable ad-hoc arm64 artifact remains available, while physical UI acceptance and notarization remain open.
- Sprint S68-toolbar-interaction-affordances: shared buttons now meet a 40px minimum target and expose a visible keyboard focus ring; 42 frontend tests, 35 Rust tests, exact arm64 installation, strict signature checks, and mounted-DMG verification pass; physical UI acceptance and Developer ID/notarization remain open.
- Sprint S69-stable-toolbar-iconography: replaced platform-dependent toolbar glyphs with accessible inline SVG icons while preserving labels/actions; 42 frontend tests, 35 Rust tests, exact arm64 installation, strict signature checks, and mounted-DMG verification pass; physical UI acceptance and Developer ID/notarization remain open.
- Sprint S70-bounded-clipboard-operations: bounded AppleScript clipboard import/Copy helpers with kill/reap cleanup and actionable timeout handling; 42 frontend tests, 35 Rust tests, exact arm64 installation, strict signature checks, and mounted-DMG verification pass; physical clipboard/UI acceptance and Developer ID/notarization remain open.
- Sprint S71-latest-revision-save-ordering: Save now prepares its rendered export after destination selection, preventing edits made during the dialog from being omitted; 42 frontend tests, 35 Rust tests, exact arm64 installation, strict signature checks, and mounted-DMG verification pass; physical export/UI acceptance and Developer ID/notarization remain open.
- Sprint S72-single-supported-product-layout: archived the stale root `dist/Shotser.app` and added fail-closed package/verification guards for duplicate root app bundles; exact arm64 installation, strict signature checks, and mounted-DMG verification pass; physical UI acceptance and Developer ID/notarization remain open.
- Sprint S73-duplicate-app-guard-verification: revalidated the exact installed app and mounted DMG and proved package/verification rejection of a temporary duplicate root `dist/*.app`; physical UI acceptance and Developer ID/notarization remain open.
- Sprint S74-permission-category-clarity: named macOS's `Screen & System Audio Recording` category in permission recovery, clarified screen-only/no-audio behavior in the bundle usage description, and passed 42 frontend tests, 35 Rust tests, exact arm64 installation, strict signature checks, helper self-tests, and mounted-DMG verification; physical UI acceptance and Developer ID/notarization remain open.
- Sprint S75-async-crop-stale-result: added synchronous image-edit revision invalidation and moved crop persistence to the guarded export boundary so delayed Crop cannot overwrite newer Reset/import/annotation state; 44 frontend tests, 36 Rust tests, exact arm64 package/install, strict signature checks, and mounted-DMG verification pass; App-level async interleavings, physical UI acceptance, and Developer ID/notarization remain open.
- Sprint S76-appkit-selector-event-evidence: added a permission-free bundled-selector AppKit event self-test for real mouse drag and Escape handlers, callback geometry, cleanup, and responder readiness; exact arm64 package/install, strict signature checks, and mounted-DMG verification pass; physical pointer/export acceptance and Developer ID/notarization remain open.
- Sprint S77-nested-helper-release-integrity: release packaging now validates Developer ID authority and matching Team ID for the separately executed bundled selector, and verifier reports its event self-test exit code; local ad-hoc package/install and mounted-DMG verification pass; Apple credentials and physical acceptance remain open.
- Sprint S78-capture-single-instance-handoff: duplicate-launch reveal is suppressed while a native capture is active, overlap is rejected, and RAII releases capture activity; exact arm64 package/install and mounted-DMG verification pass; Accessibility-enabled physical acceptance remains open.
- Sprint S55-canonical-installed-bundle-runner: root build/run/verify now installs the freshly packaged ShotEye bundle at `/Applications/ShotEye.app`, moves the previous bundle to a recoverable temporary backup, and keeps permission testing on the same exact app identity.
- Sprint S56-native-display-read-evidence: bundled selector now proves actual main-display pixel access without prompting or showing an overlay, and the installed/DMG verifier runs that gate.
- Sprint S57-permission-action-concurrency: toolbar/native-menu permission actions share one guarded lifecycle, disable together while pending, and publish only current status-epoch results; installed and mounted-DMG verification pass.
- Sprint S58-canonical-artifact-verification: installer rejects unsigned source bundles and verifier checks the exact architecture/version DMG path; installed and mounted-DMG verification pass.
- Sprint S59-canonical-writer-concurrency: Open, Paste, and Crop now share the native-operation lane with capture/export, all terminal native statuses respect status epochs, and native polling errors kill/reap their child before returning.
- Sprint S60-native-dispatch-evidence: isolated helper/system selector dispatch behind an injectable seam and added executable coverage for fallback, cancellation, failure, and timeout policy.
- Sprint S79-release-verification-mode: split local-only and release-ready verifier modes; release mode now requires Developer ID authority, matching app/helper Team IDs, Gatekeeper, and stapled app/DMG notarization. Local verification passed; the current ad-hoc package was correctly rejected by the release gate.
- Sprint S80-current-image-keyboard-actions: refreshed the editor keyboard listener when the current capture changes, preventing stale no-image Copy/Save closures after Open, Paste, Crop, or capture; exact arm64 package/install and mounted-DMG verification pass.
- Sprint S81-guarded-edit-menu-actions: routed native Edit-menu mutations through the capture-aware dispatcher and cleared transient annotation drafts on Clear/Reset; exact arm64 package/install and mounted-DMG verification pass. Packaged frontend-to-Rust IPC evidence remains next.
- Sprint S82-capture-and-shortcut-recovery: preserves valid captures across restoration errors and retries/reports startup global-shortcut fallback truthfully; exact arm64 package/install and mounted-DMG verification pass. Packaged frontend-to-Rust IPC evidence remains next.

- Sprint S83-packaged-runtime-contract-ipc: fixed the Tauri camelCase report payload, added a payload regression test, and verified the exact installed app and DMG runtime contract with a passing report; physical UI and Developer ID/notarization gates remain open.
- Sprint S84-native-capture-lifecycle-hardening: moved blocking capture to a worker boundary, made Rust the single hide/restore owner, and surfaced native restoration truth; exact installed app/DMG and packaged runtime contract pass, while delayed physical selector, Accessibility, and Developer ID/notarization gates remain open.
- Sprint S85-lifecycle-evidence-hardening: reset per-run runtime traces and recorded explicit native restoration events; exact installed app/DMG and packaged runtime contract pass, while real-selector and public-release gates remain open.
- Sprint S86-revision-stable-crop-boundary: extracted the async crop revision gate into the production path and added deterministic Crop → Reset and Crop → annotation invalidation tests; 45 frontend tests, 39 Rust tests, exact arm64 package/install, packaged runtime contract, and mounted-DMG verification pass; component-level deferred browser-work and physical/release gates remain open.
- Sprint S87-packaged-react-crop-lifecycle: added a jsdom/React Testing Library harness that drives the real Paste → Crop pointer path and proves delayed Crop → Reset and Crop → annotation interleavings preserve newer state; 47 frontend tests, 39 Rust tests, exact arm64 package/install, runtime contract, and mounted-DMG verification pass; physical/release gates remain open.
- Sprint S88-packaged-react-capture-lifecycle: extended the real App harness through Capture area success, pending re-entry protection, rejected capture recovery, and native cancellation recovery; 51 frontend tests, 39 Rust tests/check, exact arm64 package/install, runtime contract, installed verification, mounted-DMG verification, and DMG hash parity pass; physical UI, secondary-display, and Developer ID/notarization gates remain open.
- Sprint S89-packaged-react-annotated-export: extended the real App harness through annotated Copy, Save, and Drag, including canvas rasterization and Save destination ordering; 54 frontend tests, 39 Rust tests/check, exact arm64 package/install, runtime contract, installed verification, mounted-DMG verification, and DMG hash parity pass; physical export/UI and Developer ID/notarization gates remain open.

## Backlog

- Native AppKit click regression harness.
- Crop and reset crop.
- Physical Finder drag-out acceptance and lazy file-promise refinement.
- ScreenCaptureKit migration where required.
- Tauri native capture, clipboard, and save adapters.
- Capture history, repeat capture, and file-save dialog integration.

## Sprint S90-stable-local-package-identity — 2026-08-30

### Done

- Added a bounded `codesign` private-key probe for the installed `ShotEye Local Development` identity and retained explicit ad-hoc fallback when it is unavailable.
- Signed the bundled `ShotEyeSelector` first, then re-signed the containing app, producing matching local authority across the executable trust boundary.
- Rebuilt and installed the exact arm64 app; frontend 54/54, Rust 39/39, `cargo check`, shell syntax, strict installed verification, runtime contract, and mounted-DMG verification pass.
- Refreshed `artifacts/releases/ShotEye_0.1.0_aarch64.dmg` and confirmed byte/hash parity.

### Pending external gates

- Physical selector drag, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.

## Sprint S107-packaged-selector-cancellation-harness — 2026-08-30

### Done

- Added an explicit opt-in `--capture-cancel` mode to the canonical packaged Accessibility harness.
- Gated the mode on the exact installed app, native selector executable, and non-prompting Screen Recording preflight.
- Added process lifecycle assertions for `Capture area` → native selector appears → Escape → selector exits → ShotEye editor is visible.
- Corrected System Events targeting from an invalid bundle-identifier query to the real packaged `shoteye` process name.
- Ran shell syntax plus normal and opt-in blocked-state checks; current host correctly returns exit `2` with `-25211` before physical interaction.

### Pending external gates

- Run `scripts/verify_ui_smoke.sh --capture-cancel --report artifacts/tauri-e2e/s107-capture-cancel-physical-ui-smoke.txt` from an unlocked desktop with Accessibility and Screen Recording enabled. Then separately verify successful drag, shortcut invocation, Copy/Save, Finder drag, and secondary-display capture.

## Sprint S108-selector-permission-mismatch-hardening — 2026-08-30

### Done

- Stopped explicit bundled-selector Screen Recording denial before the system-selector fallback, preventing repeated consent prompts caused by a parent/helper TCC mismatch.
- Kept system fallback for only inconclusive probes and recoverable helper launch failures; preserved no-second-selector behavior for timeout and explicit denial.
- Added focused Rust coverage for probe denial, helper exit-code `3`, actionable user messaging, and the existing cancellation/launch-failure matrix.
- Rebuilt/reinstalled the arm64 package and passed full frontend, Rust, Clippy, runtime-contract, installed-package, mounted-DMG, and helper self-test checks.
- Re-ran normal and opt-in UI smoke; both correctly return `BLOCKED` with `-25211` before physical interaction.

### Pending external gates

- Run the fixed package with an unlocked desktop and Accessibility enabled. Confirm no consent loop after an intentional helper TCC mismatch, then verify physical area drag, Escape recovery, global shortcut, Copy/Save, Finder drag, and secondary-display capture.

## Sprint S109-parent-helper-permission-diagnostics — 2026-08-30

### Done

- Made `screen_capture_permission_status` an asynchronous, bounded non-prompting diagnostic that checks the exact bundled selector when available.
- Added distinct actionable messages for parent denial, parent/helper identity mismatch, inconclusive helper probe, and full availability.
- Added focused diagnostic tests and passed full Rust (42/42), frontend (71/71), TypeScript/build, `cargo check`, and Clippy checks.
- Rebuilt/reinstalled the local-signed arm64 app and refreshed the canonical DMG; installed binary marker, runtime contract, strict app/DMG verification, helper self-tests, and one-process launch pass.
- UI smoke remains correctly `BLOCKED` with `-25211` before physical interaction.

### Pending external gates

- From an unlocked Accessibility-enabled desktop, verify the new status message against the exact installed app, intentionally reproduce a parent/helper TCC mismatch without allowing a fallback prompt, then restore authorization and complete area capture/export/secondary-display acceptance.

## Sprint S102-package-refresh — 2026-08-30

### Done

- Rebuilt the current source with `ShotEye Local Development`, refreshed the canonical arm64 DMG, and installed the exact bundle at `/Applications/ShotEye.app`.
- Passed `scripts/verify_app.sh --launch --report artifacts/tauri-e2e/s102-final-installed-verification.txt`.
- Passed mounted-DMG verification with `artifacts/tauri-e2e/s102-final-dmg-verification.txt`; canonical and build DMGs are byte-identical.

### Pending external gates

- Unlock the Mac and grant Accessibility to the exact installed ShotEye bundle before physical toolbar, selector, shortcut, Clipboard/Save/Finder-drag, and secondary-display acceptance.
- Obtain Developer ID credentials and notarization access for public release.

### Review

S102 is a package/evidence refresh with no source-code changes. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. Simplify skipped because no implementation diff was introduced.

## Sprint S98-session-history-privacy-control — 2026-08-30

### Done

- Added an accessible Clear history control to the Recent captures UI.
- Cleared all in-memory session entries while preserving the current editor image and status; disabled the control during capture.
- Added real App coverage for the privacy behavior and passed focused App 16/16, combined Redact/App focused 22/22, full frontend 68/68, Rust 39/39, `cargo check`, Clippy, package/install, runtime, installed, mounted-DMG, and canonical-parity verification.

### Pending external gates

- Physical selector/shortcut/Clipboard/Save/Finder-drag/secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.
- Durable history remains deferred pending a separate privacy and storage decision.

## Sprint S99-permission-denial-before-hide — 2026-08-30

### Done

- Moved the non-prompting parent Screen Recording preflight before the editor hide transition.
- Preserved the runtime-contract exception and the existing activity guard/recovery behavior.
- Added the Rust ordering regression and passed focused 1/1, frontend 68/68, Rust 40/40, `cargo check`, Clippy, package/install, runtime, installed, mounted-DMG, and canonical-parity verification.

### Pending external gates

- Physical denied-permission UI, selector drag, shortcut, Clipboard/Save/Finder-drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.

## Sprint S100-focus-driven-permission-refresh — 2026-08-30

### Done

- Added a consent-free window-focus listener that rechecks `screen_capture_permission_status` only when ShotEye becomes focused, including return from System Settings.
- Reused the native-operation guard and status epoch so background refreshes do not overlap active capture/permission work or overwrite newer user-owned status.
- Added real App regression coverage for focus refresh and blur suppression; focused App 17/17 and full frontend 69/69 pass.
- Rebuilt/installed the exact arm64 package and passed Rust 40/40, `cargo check`, Clippy, runtime-contract, installed-bundle, mounted-DMG, and canonical-parity verification.

### Pending external gates

- Physical denied-permission UI, selector drag, shortcut, Clipboard/Save/Finder-drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.

### Review

S100 closes the status-refresh gap after changing macOS privacy settings while ShotEye is away. The refresh is read-only and consent-free; it does not replace the separate explicit Permissions action.

Verification: focused App 17/17, full frontend 69/69, Rust 40/40, `cargo check`, Clippy clean, production build, exact arm64 package/install, packaged runtime contract, installed verification, mounted-DMG verification, and canonical DMG parity.

Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session; the bounded read-only subagent audit timed out before returning, so the narrow App/test diff was manually scanned and covered by focused/full tests plus package verification. Simplify skipped because the listener reuses the existing status epoch and native-operation boundary without duplicated behavior.

## Sprint S101-packaged-baseline-audit — 2026-08-30

### Done

- Synced `origin` and confirmed `origin/main...HEAD = 0 0`; preserved the existing dirty worktree and did not commit or push.
- Re-ran the exact installed package verifier. The app launches as one exact process; app and helper signatures use `ShotEye Local Development`; permission preflight, display-read, selector-event, geometry, mixed-DPI, crop-transform, runtime-contract, mounted-DMG, and canonical DMG parity checks pass.
- Captured the physical-test boundary separately: the session was at the macOS login screen and `osascript` could not use assistive access. No physical click or drag result was promoted to acceptance evidence.

### Pending external gates

- Unlock the Mac and grant Accessibility to the exact installed ShotEye bundle before physical toolbar, selector drag, shortcut, Clipboard/Save/Finder-drag, and secondary-display acceptance.
- Obtain Developer ID credentials and notarization access for public release.

### Review

This was an evidence-only reliability audit; no production code was changed. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. The bounded read-only subagent audit timed out before returning; authoritative host verification is recorded in the installed-package report. Simplify skipped because no implementation diff was introduced.

## Sprint S97-privacy-safe-redaction — 2026-08-30

### Done

- Added first-class source-coordinate Redact annotation geometry, selection, move, resize, and undo integration.
- Rendered Redact as an opaque black block in live SVG and Copy/Save/Drag/Crop raster composition.
- Added geometry/renderer/App coverage and passed focused 22/22 plus full frontend 67/67.
- Rebuilt/installed the exact arm64 package and passed Rust 39/39, `cargo check`, Clippy, runtime, installed, mounted-DMG, and canonical-parity verification.

### Pending external gates

- Physical pointer redaction and Clipboard/Save/Finder validation, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.

## Sprint S93-session-capture-history — 2026-08-30

### Done

- Added bounded immutable session history for the eight most recent successful capture/import results.
- Added accessible thumbnail restore controls that reset source-image editing state coherently.
- Added helper tests and App-level Paste → Capture → Restore coverage.
- Rebuilt/installed the arm64 package and passed frontend 63/63, Rust 39/39, `cargo check`, runtime, installed, mounted-DMG, and canonical-parity verification.

### Pending external gates

- Physical selector drag, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.
- Durable history requires a separate privacy/storage decision.

## Sprint S95-session-history-memory-bound — 2026-08-30

### Done

- Added a 128 MiB encoded-data budget alongside the eight-entry history limit.
- Added deterministic helper eviction coverage and kept newest-first immutable insertion.
- Rebuilt/installed the exact arm64 package and passed frontend 64/64, Rust 39/39, `cargo check`, runtime, installed, mounted-DMG, and canonical-parity verification.

### Pending external gates

- Physical selector drag, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.
- `rustfmt`/`clippy` are unavailable in the current stable toolchain and must be installed before lint evidence can be claimed.

## Sprint S96-native-lint-cleanup — 2026-08-30

### Done

- Installed the missing Rust `rustfmt` and `clippy` components.
- Fixed the six available native Clippy warnings with narrow behavior-preserving changes.
- Rebuilt/installed the exact arm64 package and passed Clippy, frontend 64/64, Rust 39/39, `cargo check`, runtime, installed, mounted-DMG, and canonical-parity verification.

### Pending external gates

- `cargo fmt --check` still reports pre-existing repository-wide formatting drift; a broad reformat is intentionally deferred.
- Physical selector drag, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.

## Sprint S92-startup-readiness-and-dmg-provenance — 2026-08-30

### Done

- Serialized runtime-contract startup behind the asynchronous capture listener and added RED→GREEN coverage for the lost queued-shortcut race.
- Made packaging atomically refresh the architecture-specific canonical DMG and made verification reject requested/built DMG parity mismatches before mounting.
- Rebuilt the arm64 package, installed the exact app, and passed 58 frontend tests, 39 Rust tests/check, package/install/runtime/installed/DMG verification, and the deliberate negative parity probe.

### Pending external gates

- Physical selector drag, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.

## Sprint S91-capture-mode-entry-evidence — 2026-08-30

### Done

- Added real `App` harness coverage for Window, Full screen, and Repeat last capture actions through the existing shared capture lifecycle.
- Corrected the README verification command so it no longer points at a historical artifact report.
- Clarified stable local signing identity use and explicit ad-hoc fallback in the download/package guidance.

### Pending external gates

- Physical selector drag, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display acceptance, Developer ID signing, Gatekeeper, and notarization.

## Sprint S110-status-footer-recovery-ui — 2026-08-30

### Done

- Replaced the fixed 42px status grid row with an auto-growing responsive row and safe text wrapping.
- Added `role="status"` and `aria-live="polite"` to the footer and covered the contract in the real App harness.
- Passed focused App 20/20, full frontend 72/72, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, package/install, runtime, installed, mounted-DMG, and canonical parity verification.
- Ran both UI harness modes against `/Applications/ShotEye.app`; each correctly recorded `BLOCKED` with Accessibility error `-25211`.

### Pending external gates

- Unlock the Mac and grant Accessibility to the exact installed ShotEye bundle before physical toolbar, selector drag, shortcut, Clipboard/Save/Finder-drag, and secondary-display acceptance.
- Obtain Developer ID credentials and notarization access for public release.

### Review

S110 addresses the only reproducible source-level UI issue from the current audit: long status text could be constrained by the fixed footer row. The current source contains no duplicate traffic-light markup. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. Simplify was limited to the existing status layout because the fix is a narrow CSS/semantics change.

## Sprint S111-finder-image-drop-import — 2026-08-30

### Done

- Added typed Tauri drag-enter, drag-leave, and drag-drop handling for supported image files.
- Reused the guarded canonical `open_image` import path and added a visible drop affordance.
- Added helper coverage for image extension and malformed-payload boundaries plus real App coverage for mixed Finder drops.
- Passed focused App 21/21, image-drop helper 10/10, full frontend 83/83, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, package/install, runtime, installed, mounted-DMG, and canonical parity verification.

### Pending external gates

- Physical Finder drop, toolbar, selector drag, shortcut, Clipboard/Save, and secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S111 adds a local-first Finder workflow without introducing a second image state or native import boundary. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S112-privacy-safe-pixelate-annotation — 2026-08-30

### Done

- Added Pixelate to the source-coordinate annotation union, tool routing, selection, translation, resizing, and meaningful-annotation rules.
- Added block-sampling raster composition with an opaque black fail-closed fallback when canvas pixel reads are unavailable.
- Added a visible Pixelate preview pattern and real App coverage for Pixelate → annotated Copy.
- Passed focused annotation/App 32/32, full frontend 87/87, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, package/install, runtime, installed, mounted-DMG, and canonical parity verification.

### Pending external gates

- Physical Pixelate interaction and remaining Accessibility-enabled toolbar, selector, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S112 keeps Pixelate on the existing privacy annotation/export boundary. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S113-privacy-safe-blur-annotation — 2026-08-30

### Done

- Added Blur to the source-coordinate annotation union, tool routing, selection, translation, resizing, and meaningful-annotation rules.
- Added bounded separable blur raster composition with an opaque black fail-closed fallback when canvas pixel reads are unavailable.
- Added a clipped live Blur preview and real App coverage for Blur → annotated Copy.
- Extended the independent UI harness's accessible-control inventory to include Pixelate and Blur.
- Passed focused annotation/App 36/36, full frontend 91/91, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, shell syntax, package/install, runtime, installed, mounted-DMG, and canonical parity verification.

### Pending external gates

- Physical Blur/Pixelate interaction and remaining Accessibility-enabled toolbar, selector, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance; current smoke is `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S113 keeps Blur on the existing source-coordinate privacy/export boundary and fails closed when pixel reads cannot be trusted. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S114-native-tools-menu — 2026-08-30

### Done

- Added the native macOS Tools menu with Select, Crop, Arrow, Rectangle, Text, Draw, Redact, Pixelate, and Blur.
- Routed native Tools callbacks through the current React tool-selection dispatcher shared with the toolbar.
- Added menu-model coverage and real App coverage for native Tools → Blur state routing.
- Passed focused menu/App 26/26, full frontend 92/92, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, shell syntax, package/install, runtime, installed, and mounted-DMG verification.

### Pending external gates

- Physical menu/toolbar interaction, selector drag, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance; current smoke is `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S114 keeps the native menu as a thin alternate command surface over current React action refs; it does not duplicate editor behavior. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S115-repeat-capture-keyboard-shortcut — 2026-08-30

### Done

- Added `⌘⇧R`/`⌃⇧R` to the shared editor shortcut mapping.
- Routed keyboard repeat through the existing guarded `repeat_last_capture` action.
- Added focused helper coverage and real App keyboard-event coverage.
- Passed focused shortcut/App 30/30, full frontend 94/94, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, package/install, runtime, installed, and mounted-DMG verification.

### Pending external gates

- Physical shortcut invocation and remaining selector, toolbar/menu, Clipboard/Save, Finder-drop, and secondary-display acceptance; current smoke is `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S115 uses the existing editor shortcut and exclusive capture paths without adding a second capture implementation. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S116-repeat-shortcut-discoverability — 2026-08-30

### Done

- Added the visible `⌘⇧R` Repeat Last Capture toolbar hint with `aria-keyshortcuts` and tooltip metadata.
- Added `CmdOrCtrl+Shift+R` to the native Capture menu while preserving the shared guarded repeat action.
- Passed focused menu/App 28/28, full frontend 95/95, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, package/install, runtime, installed, and mounted-DMG verification.

### Pending external gates

- Physical shortcut/menu/toolbar interaction and remaining selector, Clipboard/Save, Finder-drop, and secondary-display acceptance; current smoke is `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S116 is a small behavior-bearing discoverability change with focused regression coverage and a manual diff scan. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S117-canonical-repeat-shortcut — 2026-08-30

### Done

- Centralized the Repeat Last Capture registration string and derived the native-menu accelerator and ARIA representation from it.
- Added focused shortcut-display contract coverage while preserving the real App toolbar metadata regression.
- Passed focused shortcut/menu/App 33/33, full frontend 96/96, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, package/install, runtime, installed, and mounted-DMG verification.

### Pending external gates

- Physical shortcut/menu/toolbar interaction and remaining selector, Clipboard/Save, Finder-drop, and secondary-display acceptance; current smoke is `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S117 is a small contract refactor with proof-first coverage and a manual diff scan. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S118-primary-toolbar-shortcuts — 2026-08-30

### Done

- Added visible shortcut hints, tooltips, and ARIA metadata to the primary Open, Paste, Copy, Save, Undo, Redo, and Repeat toolbar controls.
- Centralized primary shortcut values and derived native-menu accelerators from the shared contract.
- Passed focused menu/shortcut/App 35/35, full frontend 98/98, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, package/install, runtime, installed, and mounted-DMG verification.

### Pending external gates

- Physical shortcut/menu/toolbar interaction and remaining selector, Clipboard/Save, Finder-drop, and secondary-display acceptance; current smoke is `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S118 is a behavior-bearing toolbar discoverability change with proof-first coverage and a manual diff scan. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S119-release-notarization-order — 2026-08-30

### Done

- Added the shared `scripts/release_notarization.sh` boundary for app and DMG submission, stapling, and validation.
- Moved release app notarization/stapling before DMG creation and DMG notarization/stapling before canonical artifact refresh.
- Added `scripts/test_release_packaging_order.sh`; it passed along with shell syntax, frontend, Rust, package, install, runtime, installed-bundle, and mounted-DMG checks.

### Pending external gates

- Configure a real Developer ID identity and Apple notarization credentials, then run release Gatekeeper/notarization verification.
- Run physical selector, shortcut, toolbar, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current smoke is `BLOCKED` by `-25211`.

### Review

S119 is a bounded release-pipeline change with proof-first regression coverage and a manual diff scan. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S120-area-permission-identity — 2026-08-30

### Done

- Aligned area-capture preflight and status messaging with the bundled selector grant that performs the pixel read.
- Added regressions for parent-denied/selector-granted readiness and denial-safe effective permission handling.
- Passed focused/full frontend and Rust checks, build, Clippy, package/install, runtime, installed-bundle, mounted-DMG, and release-order verification.

### Pending external gates

- Physical selector, shortcut, toolbar, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current smoke remains `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization for public release.

### Review

S120 is a bounded permission-identity fix with RED→GREEN regression coverage and a manual diff scan. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S121-selector-aware-permission-recovery — 2026-08-30

### Done

- Updated the Permissions action to inspect the exact bundled `ShotEyeSelector` before calling macOS consent APIs.
- Added non-prompting handling for authorized, denied, and inconclusive selector states, preserving fail-closed capture behavior.
- Passed Rust 45/45, frontend 98/98, TypeScript/Vite build, `cargo check`, Clippy, shell syntax, package/install, runtime, installed-bundle, mounted-DMG, and release-mode rejection checks.

### Pending external gates

- Physical selector, shortcut, toolbar, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current UI automation remains blocked by `-25211`.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S121 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S122-helper-output-boundary — 2026-08-30

### Done

- Added a permission-free bundled-selector output self-test that exercises production compositor and ImageIO PNG writing with deterministic synthetic display inputs.
- Extended installed and mounted-DMG verification to require a valid `8×4` PNG and record its SHA-256.
- Rebuilt the exact arm64 package; runtime contract, package/install, mounted-DMG, shell syntax, and release-order checks passed.

### Pending external gates

- Physical selector, toolbar, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S122 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S123-native-operation-ux — 2026-08-30

### Done

- Added phase-aware React state for the shared native-operation lane.
- Gated competing Copy, Save, Drag, capture, import, permission, settings, repeat, and shortcut actions while native work is pending.
- Preserved annotation editing during the Save dialog and delayed export preparation until after destination selection.
- Added deferred lifecycle coverage: focused App 30/30 and full frontend 101/101; TypeScript/Vite, Rust 45/45, `cargo check`, Clippy, package/install, runtime, installed-app, mounted-DMG, shell, and release-order checks passed.
- Recorded `artifacts/tauri-e2e/s123-runtime-contract.txt`, `artifacts/tauri-e2e/s123-final-installed-verification.txt`, and `artifacts/tauri-e2e/s123-final-dmg-verification.txt`.

### Pending external gates

- Physical selector, toolbar, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current automation remains blocked by `-25211`.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S123 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. Independent review was requested separately and did not modify the worktree.

## Sprint S124-shortcut-conflict-recovery — 2026-08-30

### Done

- Added visible shortcut registration state and a compact Default/reset settings control.
- Serialized explicit shortcut replacement, gated capture/export actions while it is pending, and preserved the previous active shortcut after conflict rejection.
- Formatted native registration errors into macOS shortcut notation.
- Passed focused App 31/31, shortcut display 7/7, full frontend 103/103, TypeScript/Vite, Rust 45/45, `cargo check`, Clippy, package/install, runtime, installed-bundle, mounted-DMG, shell, and release-order checks.
- Recorded `artifacts/tauri-e2e/s124-runtime-contract.txt`, `artifacts/tauri-e2e/s124-final-installed-verification.txt`, and `artifacts/tauri-e2e/s124-final-dmg-verification.txt`.

### Pending external gates

- Physical shortcut conflict, selector, toolbar, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current automation remains blocked by `-25211`.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S124 is locally verified and packaged. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S125-canonical-launch-single-instance — 2026-08-30

### Done

- Changed supported build/run and installed verification launch commands from `open -n` to `open -a` for the exact `/Applications/ShotEye.app` bundle.
- Added `scripts/test_canonical_launch.sh` and passed its canonical-path, architecture-specific-output, and no-multi-instance checks.
- Moved the stale unqualified generated bundle to `/tmp/shoteye-retired-target-release-20260830.app` without deleting it.
- Hardened `scripts/package_app.sh` to archive stale unqualified generated bundles automatically and fail closed if one is running.

### Pending external gates

- Physical and package gates: the refreshed arm64 app and canonical DMG pass runtime, installed-bundle, mounted-DMG, helper output, deep-signature, and DMG parity verification. Reports: `artifacts/tauri-e2e/s125-runtime-contract.txt`, `artifacts/tauri-e2e/s125-final-installed-verification.txt`, and `artifacts/tauri-e2e/s125-final-dmg-verification.txt`. Canonical DMG SHA-256: `a61e7616f05f3e617b0a8e76c999773cf610b954c98c4221778a3fee879fb260`.
- Physical selector, toolbar, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current automation remains blocked by `-25211`.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S125 launch-contract implementation is locally focused and safe. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S126-package-time-stale-bundle-hardening — 2026-08-30

### Done

- Added package-time remediation for stale unqualified generated ShotEye bundles, with recoverable archival outside the build tree.
- Added a live-process guard that fails closed rather than moving a competing executable.
- Added an installed/mounted-DMG verifier guard that fails closed if the unqualified generated bundle reappears.
- Passed the canonical-launch and release-order contracts, rebuilt/reinstalled the arm64 app, and passed runtime, installed-bundle, mounted-DMG, helper output, strict-signature, and DMG parity verification.
- Recorded `artifacts/tauri-e2e/s126-runtime-contract.txt`, `artifacts/tauri-e2e/s126-final-installed-verification.txt`, and `artifacts/tauri-e2e/s126-final-dmg-verification.txt`.

### Pending external gates

- Physical selector, toolbar, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; `artifacts/tauri-e2e/s126-physical-ui-smoke.txt` is `BLOCKED` by `-25211`.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S126 package-boundary hardening is locally verified. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S127-mounted-dmg-launch-provenance — 2026-08-30

### Done

- Fixed mounted-DMG launch verification for the shared single-instance bundle identifier by stopping only the exact installed test process before launch.
- Canonicalized symlinked macOS temporary paths for reliable process counting and cleanup.
- Passed mounted-DMG launch verification and confirmed the report is non-empty, the mounted volume is detached, the payload process is gone, and the canonical installed app was relaunched as one process.
- Recorded `artifacts/tauri-e2e/s127-dmg-launch-verification.txt`.

### Pending external gates

- Physical selector, toolbar, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current automation remains blocked by `-25211`.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S127 mounted-DMG launch provenance is locally verified. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session. No subagent modified the worktree.

## Sprint S128-capture-orientation-and-toolbar-sizing — 2026-08-30

### Done

- Confirmed the mirrored/rotated preview was produced by the native compositor's extra y-axis reflection.
- Updated the existing mixed-DPI and output-boundary self-tests to require correct visual top-to-bottom output and avoid `UInt8` predicate overflow.
- Removed the extra reflection and reduced bundled toolbar SVG glyphs to 16px while retaining accessible 40px button targets.

### Pending verification and external gates

- Physical selector, toolbar, shortcut, Clipboard/Save, Finder-drop, and secondary-display acceptance on an unlocked Accessibility-enabled desktop; current automation remains blocked by `-2700` (`Missing accessible button: Open image`).
- Developer ID signing, Gatekeeper, and notarization.

### Verification evidence

- Fresh frontend, Rust, native helper, installed-app, mounted-DMG, runtime-contract, and DMG-launch checks pass. Reports: `artifacts/tauri-e2e/s128-runtime-contract.txt`, `s128-final-installed-verification.txt`, `s128-final-installed-post-dmg-verification.txt`, `s128-final-dmg-verification.txt`, and `s128-dmg-launch-verification.txt`.
- Canonical Apple Silicon DMG: `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`; SHA-256 `5e9c6d89c49f1698fdef176dac65fc3bc02be59c95aad3669c0f7c08dba52cd8`.

### Review

S128 code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S129-packaged-capture-acceptance-and-ax-harness — 2026-08-30

### Done

- Corrected the Accessibility smoke harness to use the real native Tools/Capture menu path when WKWebView DOM button roles are absent from System Events.
- Passed installed-package Capture Area cancellation: selector observed, Escape delivered, selector exited, and the ShotEye editor returned as the main non-minimized window.
- Passed installed-package HID area selection and validated the resulting `600×500` PNG through ShotEye's own Copy Capture clipboard path.
- Evidence: `artifacts/tauri-e2e/s129-physical-ui-menu-smoke.txt`, `s129-capture-cancel-smoke.txt`, and `s129-capture-success.png`.

### Pending external gates

- Physical toolbar pointer, global shortcut, Finder-drop, and secondary-display acceptance.
- Developer ID signing, Gatekeeper, and notarization.

### Review

S129 packaged capture acceptance is locally verified. The WebView DOM Accessibility limitation is recorded separately from native-menu/HID evidence. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S130-nested-toolbar-accessibility-harness — 2026-08-30

### Done

- Fixed the UI smoke harness to traverse nested WebView Accessibility controls and classify Pin as an `AXCheckBox`.
- Passed 25 packaged editor-control checks, six application-menu checks, and reversible `Rectangle`/`Select` toolbar clicks.
- Evidence: `artifacts/tauri-e2e/s130-physical-ui-toolbar-smoke.txt`.

### Pending external gates

- Global shortcut, Finder-drop, secondary-display, Developer ID signing, Gatekeeper, and notarization acceptance.

### Review

S130 nested toolbar Accessibility acceptance is locally verified. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S131-toolbar-capture-acceptance — 2026-08-30

### Done

- Passed the actual installed `Capture area` toolbar control through the nested Accessibility tree.
- Passed real HID selection, selector exit, editor restoration, and ShotEye Copy Capture clipboard validation as a `600×500` PNG.
- Evidence: `artifacts/tauri-e2e/s131-toolbar-capture-success.txt` and `s131-toolbar-capture-success.png`.

### Pending external gates

- Global shortcut, Finder-drop, secondary-display, Developer ID signing, Gatekeeper, and notarization acceptance.

### Review

S131 toolbar capture acceptance is locally verified for one display. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Sprint S132-global-shortcut-acceptance — 2026-08-30

### Done

- Passed default `⌘⇧Y` capture routing while Finder was frontmost, including Escape cancellation and editor restoration.
- Passed custom `⌘⇧U` recording/triggering through the installed toolbar and verified reset to a working default shortcut.
- Evidence: `artifacts/tauri-e2e/s132-shortcut-acceptance.txt`.

### Pending external gates

- Occupied-shortcut conflict and alternate keyboard-layout acceptance.
- Finder-drop, secondary-display, Developer ID signing, Gatekeeper, and notarization acceptance.

### Review

S132 global shortcut acceptance is locally verified. Code review: skipped (ce-code-review unavailable) — no CE review invocation primitive is exposed in this session.

## Done — S135/S137 orientation and Finder drag hardening

- Fixed the native compositor path that produced vertically mirrored/rotated output and verified a real installed-package Copy result is upright (`800×700`, valid PNG).
- Passed originating WebView pointer coordinates through the native drag command, converted AppKit coordinates for flipped/unflipped views, and created the synthetic event in window-base coordinates.
- Retained private drag staging through Finder consumption and passed an isolated installed-package Finder drop.
- Evidence: `artifacts/tauri-e2e/s135-orientation-acceptance.txt`, `s135-current-orientation.png`, `s137-finder-drop-acceptance.txt`, `s137-finder-drop/ShotEye Capture.png`, and `s137-drag-lifecycle-installed.txt`.

## Pending — S135/S137 release gates

- Secondary-display capture and alternate keyboard-layout/occupied-shortcut acceptance require additional hardware or OS state.
- Developer ID signing, Gatekeeper, and notarization require Apple credentials; the current `ShotEye Local Development` identity is local-only.
## Done — S138 installed Save acceptance (2026-08-30)

- Exact installed ShotEye package completed fresh Capture area → physical selection → Save capture.
- PNG evidence: `artifacts/tauri-e2e/s138-tauri-save-acceptance.png` (`1000×800`, 66,800 bytes); report: `artifacts/tauri-e2e/s138-save-acceptance.txt`.
- Open image smoke was exercised. Reopen pixel-equivalence remains unclaimed because packaged WebView status is not exposed to Accessibility.

## Pending release gates after S138

- Secondary display, occupied shortcut/alternate keyboard layout, and Developer ID/notarization remain pending.
## Done — S139 release-gate audit (2026-08-30)

- Release verifier correctly rejected `/Applications/ShotEye.app` because only the local `ShotEye Local Development` identity is available.
- Evidence: `artifacts/tauri-e2e/s139-release-gate-output.txt`.
## Done — S140 final local package verification (2026-08-30)

- Installed app and canonical DMG passed arm64 package verification, helper self-tests, PNG output-boundary validation, and launch cleanup.
- Evidence: `artifacts/tauri-e2e/s140-final-installed-verification.txt`.
## Gate inventory — S141 (2026-08-30)

- One display detected; secondary-display verification remains external.
- Occupied shortcut was not claimed because Accessibility exposure was inconsistent; see `artifacts/tauri-e2e/s141-hardware-and-shortcut-gates.txt`.

## Done — S148 repeatable physical capture acceptance (2026-09-02)

- Added `scripts/test_physical_area_capture.sh` and passed fresh exact-installed Capture Area → HID drag → Copy PNG acceptance (`1000×800`, upright visual inspection).
- Serial Capture Area → Escape cancellation and installed/DMG package verification also passed.
- Evidence: `artifacts/tauri-e2e/s148-physical-area-copy.txt`, `s148-physical-area-copy.png`, `s148-capture-cancel-serial.txt`, and `s148-package-verification.txt`.
- Two additional serial primary-display runs passed after artifact-path hardening: `s149-physical-area-copy.*` and `s150-physical-area-copy.*`.

## Pending — S148 external gates

- The Carbon fixture cannot prove an exclusive occupied shortcut on this macOS host; `shortcut-conflict-acceptance.txt` is deliberately `BLOCKED`.
- Secondary-display capture and Developer ID/Gatekeeper/notarization require external hardware and Apple credentials.

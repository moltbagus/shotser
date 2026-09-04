# ShotEye PRD v1.01

## Product

ShotEye is a native macOS screenshot utility for capturing an area, window, or display and immediately copying, saving, and annotating the result.

## Current outcome

The foreground editor opens as an active macOS application, accepts toolbar input, and exposes a repeatable capture-to-copy/save workflow.

- S89 adds real App-level annotated Copy, Save, and Drag evidence, including canvas rasterization and Save destination ordering; the focused harness passes 9 tests and the full frontend suite passes 54 tests.
- S90 makes local packaging identity-aware: when `ShotEye Local Development` can actually sign non-interactively, the app and bundled selector are signed with the same stable identity; if the key is unavailable, packaging preserves the explicitly local ad-hoc fallback. The installed arm64 app and DMG pass local verification with matching app/helper authority.
- S91 adds real `App` entry-point coverage for Window, Full screen, and Repeat capture, and corrects the documented local-package signing behavior. S92 closes startup readiness ordering and canonical DMG provenance; S93 adds bounded session capture history with restore controls; S95 adds a total encoded-data budget so large histories cannot grow memory without bound; S96 removes the available native Clippy warnings; S97 adds privacy-safe Redact annotations; S98 adds an explicit session-history privacy control; S99 rejects known Screen Recording denial before hiding the editor; S100 refreshes Screen Recording status when the editor regains focus without requesting consent. The full frontend suite now passes 69 tests and the native suite passes 40 tests. Physical desktop acceptance remains separate.
- S101 revalidated the exact installed arm64 package after the stable local signing identity was selected: the app/helper share `ShotEye Local Development`, helper Screen Recording preflight and Core Graphics display-read both return success, and the packaged runtime/bundle/DMG checks remain green. Physical pointer acceptance was not claimed because this session was at the macOS login screen and Accessibility automation was denied.
- S102 refreshed the package from the current source, reinstalled the exact arm64 bundle, and reverified the installed app plus mounted canonical DMG. The stable local app/helper authority remains intact and all noninteractive capture-boundary checks pass; physical UI acceptance is still pending the unlocked Accessibility-enabled desktop.
- S103 adds a checked-in `scripts/verify_ui_smoke.sh` harness that targets only the canonical installed ShotEye bundle, enforces one exact process, and checks the accessible editor controls and native application menus. It fails closed with an artifact when the desktop is locked or Accessibility is denied.
- S105 extends that harness with four reversible representative toolbar clicks (`Rectangle`, `Select`, `Pin`, `Unpin`) so the reported non-clickable-icon symptom is exercised when Accessibility is available; the current host still fails closed before clicks because assistive access is denied.
- S106 coalesces duplicate in-flight focus permission refreshes so macOS activation noise cannot issue redundant TCC status IPC calls; the regression reproduced red before the guard and passes green after it. The fixed arm64 package and DMG pass local verification.

## Current scope

- Area capture with multi-monitor pointer selection.
- Window and fullscreen capture.
- Native window capture starts in macOS window-selection mode and uses the same validated canonical image pipeline as area and fullscreen capture.
- Rectangle, arrow, text, and freehand annotations with color, stroke, undo, clear, and zoom controls.
- Solid black Redact, Pixelate, and Blur annotations with source-coordinate resizing and export-time rasterization for privacy-safe masking.
- Select, move, resize, delete, and undo annotation edits without changing the source image.
- Open PNG/JPEG/TIFF files and import PNG/TIFF clipboard images into the same canonical editor model.
- Repeat last capture.
- Bounded session capture history with thumbnail restore controls; history is intentionally cleared when ShotEye relaunches until durable history storage is designed.
- Session history is bounded by eight entries and 128 MiB of encoded data, retaining newest-first behavior under memory pressure.
- Clear history explicitly forgets recent session entries without deleting the current editor image, and is disabled while capture is active.
- Configurable global area shortcut.
- The root build/run workflow installs and launches the exact packaged bundle at `/Applications/ShotEye.app`, keeping macOS permission identity aligned with verification.
- Supported launch and verification commands focus one canonical installed `/Applications/ShotEye.app` with `open -a`; they do not create a second process from an unqualified build-tree bundle, preventing duplicate windows and permission-identity drift.
- Package-time cleanup also archives a stale unqualified generated bundle outside the build tree, or fails closed if that competing executable is still running.
- Mounted-DMG launch verification stops only the exact installed test process before launching the same-identifier payload, normalizes macOS `/var`/`/private/var` paths, and cleans up the payload process before detaching the image.
- A conflict on the default global shortcut cannot prevent the editor from launching; the UI reports the conflict so a replacement can be recorded.
- Native-feeling editor shortcuts for Undo/Redo, Open, Paste, Copy, Save, and Repeat Last Capture (`⌘⇧R`).
- Primary toolbar commands visibly advertise their macOS shortcuts (`⌘O`, `⌘V`, `⌘C`, `⌘S`, `⌘Z`, `⌘⇧Z`, and `⌘⇧R`) with matching accessibility metadata and native-menu accelerators.
- Bundled AppKit multi-display selector behind the stable Rust capture command, with `screencapture` fallback when the helper is unavailable.
- Native AppKit Drag export for the latest annotated PNG, with private staging and drag-session lifetime cleanup.
- Mutually exclusive user-triggered Copy, Save, and Drag exports with latest-revision protection.
- Checked-in install-level package verification for identity, architecture, parity, signature, helper preflight, and evidence artifacts.
- One exclusive native-operation lane spanning capture, Copy, Save, and Drag.
- Native macOS File, Capture, Edit, Tools, and Help menus delegate to the same current guarded editor actions as the toolbar.
- Repeat Last Capture is discoverable in both primary command surfaces: the toolbar shows `⌘⇧R` and the native Capture menu advertises `CmdOrCtrl+Shift+R` while delegating to the same guarded action.
- Repeat Last Capture's registration syntax, native-menu accelerator, display label, and ARIA key-shortcut value are generated from one canonical frontend contract.
- Multi-monitor area selection rejects display-gap rectangles transactionally, and the bundled selector is launched only after an affirmative permission probe.
- Startup status probes are epoch-guarded so delayed permission, shortcut, menu, or listener results cannot overwrite a later user action.
- Screen Recording preflight runs before the editor hide transition, so a known-denied capture reports the permission recovery path without briefly hiding the usable editor.
- When ShotEye regains focus after the user visits System Settings, it performs a non-prompting Screen Recording status refresh; blur events do not trigger a check, and stale refresh results cannot overwrite a newer user action.
- Background Drag prewarming renders into revision-scoped memory only; the guarded user export operation is the sole writer to Rust-owned rendered capture state.
- Local packaging builds the signed `.app` with Tauri and creates the DMG directly with `hdiutil`, avoiding a blocking Finder cosmetic script; the verifier can inspect the exact mounted DMG payload.
- The bundled compositor uses an explicit RGBA context with nearest-neighbor mixed-DPI scaling and a documented floor/ceil backing-coordinate policy; its executable self-test checks output size, seam ownership, vertical orientation, opaque coverage, and every output pixel.
- The native selector has a permission-free crop-transform self-test covering top/bottom display rows and exact backing-pixel bounds; the macOS Screen Recording settings opener is bounded so permission recovery cannot hang the editor.
- Native capture children have a bounded five-minute lifetime and are killed on timeout so a stuck selector cannot hold the editor operation lane forever.
- Open and Paste share the same native-operation lane as capture and export because they replace Rust-owned canonical image state. Crop remains in that lane for decode/state ordering, while its React image edit is persisted only by the guarded Copy, Save, or Drag export boundary; terminal statuses are epoch-guarded so a newer user action owns the status line.
- Native child polling kills and reaps the child before returning a polling error, preventing a leaked selector from surviving after the frontend releases its operation lane.
- The helper/system selector decision is isolated behind an injectable dispatch seam, with executable coverage for affirmative helper use, permission and probe fallback, cancellation, helper failure, and timeout no-fallback behavior.
- The frontend hidden-window capture lifecycle is isolated behind an executable helper that covers hide/action/restore/focus ordering, attempts focus even when show fails, and keeps restore failures distinct from capture failures.
- Native capture, import, permission, Copy, Save, and Drag phases are exposed as one observable UI state. Competing native actions are disabled while the lane is busy; the editor remains available during the user-controlled Save dialog and the footer explains the current phase.
- Global capture shortcut registration is observable and conflict-safe: the settings control shows Active, Registering, Conflict, or Not active, preserves the last active shortcut when a replacement is rejected, offers a Default reset, and gates capture/export actions during an in-flight registration.
- The native selector centralizes drag normalization and exposes a permission-free selection self-test for forward, reverse, and below-minimum gestures.
- The root build/run entry points target only the Tauri ShotEye bundle; the earlier Swift prototype is isolated as reference code.
- The packaged native executable and Rust crate use the product identity `shoteye`; root smoke/log checks do not depend on the framework template name `tauri-app`.
- Copy/save toolbar actions; OCR and QR extraction remain future native integrations.

## Next backlog

- Extend the native AppKit interaction harness with Accessibility-enabled acceptance when available.
- Complete independent Finder drag-out acceptance and dropped-file reopen validation.
- Improve ScreenCaptureKit compatibility and permissions guidance.
- Add deterministic AppKit/Accessibility acceptance coverage for shortcut startup, pointer cancellation, and Finder drop.
- Run the guarded Developer ID/notarized release pipeline when Apple signing and notarization credentials are available.
- Require the bundled AppKit selector to carry the same Developer ID authority and Team ID as the outer app before release packaging can pass.
- Keep the local self-signed identity as evaluation-only: it has no TeamIdentifier and is rejected by Gatekeeper, so Developer ID signing and notarization remain release gates.
- Decide whether durable history should be opt-in and privacy-preserving before adding persistence beyond the current session.

## S123 phase-aware native-operation UX — 2026-08-30

- Added a React-visible native-operation phase for capture, import, permission, Copy, Save-dialog, Save, and Drag work. The phase is cleared from every success, cancellation, error, and `finally` path so a failed native operation cannot leave the editor permanently disabled.
- Added visible live progress labels and action gating: Copy, Save, Drag, capture modes, imports, repeat, permissions, settings, and shortcut recording cannot overlap a native operation. Annotation tools and controls remain usable while the Save destination dialog is open, preserving the latest revision before Save preparation begins.
- Added deferred App coverage for Copy and Drag progress/lane release plus Save-dialog editability. The focused App suite passes 30/30 and the full frontend suite passes 101/101 across 16 files.
- S123 verification: TypeScript/Vite build, Rust 45/45, `cargo check`, Clippy, arm64 local package/install, serialized runtime contract, installed-bundle verification, mounted-DMG verification, shell checks, and canonical DMG refresh all pass.
- Reports: `artifacts/tauri-e2e/s123-runtime-contract.txt`, `artifacts/tauri-e2e/s123-final-installed-verification.txt`, and `artifacts/tauri-e2e/s123-final-dmg-verification.txt`. Physical pointer/shortcut/export acceptance remains external and blocked by Accessibility `-25211`; Developer ID, Gatekeeper, and notarization remain open.

## S124 shortcut conflict recovery UX — 2026-08-30

- Added explicit shortcut registration state and a compact global-capture settings control with Active/Registering/Conflict/Not active feedback and a Default reset action.
- Shortcut replacement is serialized. While registration is pending, capture/export actions and shortcut recording are disabled, global capture events are ignored with recovery status, and a rejected replacement preserves the previously active shortcut.
- Registration errors and native conflict responses now render shortcut values in macOS notation instead of leaking `CommandOrControl+…` syntax.
- Added App coverage for deferred registration, capture gating, conflict feedback, and active-shortcut preservation; shortcut-display coverage now includes formatted native rejection errors. Full frontend coverage is 103/103 across 16 files.
- S124 verification: TypeScript/Vite build, Rust 45/45, `cargo check`, Clippy, arm64 local package/install, serialized runtime contract, installed-bundle verification, mounted-DMG verification, shell checks, release-order checks, and canonical DMG refresh all pass.
- Reports: `artifacts/tauri-e2e/s124-runtime-contract.txt`, `artifacts/tauri-e2e/s124-final-installed-verification.txt`, and `artifacts/tauri-e2e/s124-final-dmg-verification.txt`. Physical shortcut/capture/export acceptance remains blocked by Accessibility `-25211`; Developer ID, Gatekeeper, and notarization remain open.

## S125 canonical launch single-instance safety — 2026-08-30

- Updated the supported build/run and installed-package verification launch paths to use `open -a` against the exact `/Applications/ShotEye.app` bundle. This focuses the canonical instance instead of explicitly requesting a new process with `open -n`.
- Hardened `scripts/package_app.sh` to archive stale unqualified generated bundles before building, while failing closed if the stale executable is live.
- Added `scripts/test_canonical_launch.sh`, which checks the supported launch scripts for the canonical installed path, architecture-specific build output, and absence of the multi-instance flag.
- Archived the stale generated unqualified target bundle recoverably at `/tmp/shoteye-retired-target-release-20260830.app`; no source or user data was deleted.
- Focused launch-contract and release-order checks pass. The refreshed arm64 app and canonical DMG pass runtime, installed-bundle, mounted-DMG, helper output, and strict-signature verification; physical Accessibility interaction and Developer ID/notarization remain separate gates.

## S126 package-time stale-bundle hardening — 2026-08-30

- Hardened `scripts/package_app.sh` so direct package invocations archive an unqualified generated `target/release` ShotEye bundle outside the build tree before producing the architecture-specific package.
- The package boundary fails closed when that stale executable is live, avoiding a silent move of a process that could still own a different macOS permission identity.
- Hardened `scripts/verify_app.sh` to reject an unqualified generated `target/release` bundle if it is present during acceptance.
- The refreshed arm64 app and canonical DMG pass package, install, runtime, installed-bundle, mounted-DMG, helper output, strict-signature, and parity verification. Reports are under `artifacts/tauri-e2e/s126-*`; the physical UI harness remains blocked by Accessibility `-25211`.

## S127 mounted-DMG launch provenance — 2026-08-30

- Fixed the mounted-DMG verifier so the exact payload can be launched even when the installed ShotEye instance is already running. The verifier stops only that exact installed test process because both bundles share the single-instance identifier.
- Normalized symlinked macOS temporary paths when counting and cleaning the mounted payload process, preventing resource-busy mounts and leaked test instances.
- Mounted-DMG launch verification passes and records `artifacts/tauri-e2e/s127-dmg-launch-verification.txt`; the canonical installed app was relaunched afterward and remains one process.
- This proves package launch provenance, not physical pointer capture, Accessibility interaction, Developer ID signing, Gatekeeper acceptance, or notarization.

## S128 capture orientation and compact toolbar affordances — 2026-08-30

- Fixed the native compositor's extra y-axis reflection. `CGDisplayCreateImage` results now stay in Quartz's default bitmap coordinate system, preventing captured previews and exported PNGs from appearing vertically mirrored or rotated.
- Strengthened the existing mixed-DPI and helper output-boundary self-tests to require visual top-to-bottom band order. The color predicates widen `UInt8` values before arithmetic so a regression reports a clean failure instead of trapping on overflow.
- Reduced ShotEye's bundled toolbar SVG glyphs from 18px to 16px while preserving the existing 40px button hit target, visible labels, focus ring, and action handlers.
- Focused native helper checks, the installed `/Applications/ShotEye.app`, and the canonical mounted-DMG payload all pass after the fix. Evidence is recorded in `artifacts/tauri-e2e/s128-runtime-contract.txt`, `s128-final-installed-verification.txt`, `s128-final-installed-post-dmg-verification.txt`, `s128-final-dmg-verification.txt`, and `s128-dmg-launch-verification.txt`; the refreshed Apple Silicon DMG SHA-256 is `5e9c6d89c49f1698fdef176dac65fc3bc02be59c95aad3669c0f7c08dba52cd8`. Physical pointer-selection acceptance remains separate and is currently blocked by Accessibility automation (`-2700`), requiring an unlocked desktop with Accessibility enabled.

## S129 packaged capture acceptance and Accessibility harness — 2026-08-30

- Corrected the packaged UI smoke harness to use ShotEye's accessible native menus when the WKWebView does not expose DOM button roles to System Events. The report now distinguishes native-menu acceptance from physical toolbar pointer acceptance instead of treating the WebView AX limitation as a missing product control.
- The exact installed package passed `Capture → Capture Area` launch, selector observation, Escape cancellation, selector exit, and editor restoration. Evidence: `artifacts/tauri-e2e/s129-capture-cancel-smoke.txt`.
- The exact installed package also accepted a real HID drag through the native selector; ShotEye's own `File → Copy Capture` path produced a valid `600×500` PNG on the clipboard. Evidence: `artifacts/tauri-e2e/s129-capture-success.png` and `artifacts/tauri-e2e/s129-physical-ui-menu-smoke.txt`.
- This proves the packaged native capture and Copy path, not physical toolbar pointer/shortcut/Finder-drop behavior, secondary-display interaction, or public Developer ID/notarization trust.

## S130 nested toolbar Accessibility harness — 2026-08-30

- Corrected the packaged smoke harness to traverse the complete WebView Accessibility tree. ShotEye toolbar controls live below the window's `AXWebArea`; direct-child lookup saw only the native traffic lights and produced a false failure. The Pin control is correctly handled as an `AXCheckBox`, not assumed to be an `AXButton`.
- The exact installed package now reports 25 editor controls and six application menus, and passes reversible `Rectangle` and `Select` toolbar clicks. Evidence: `artifacts/tauri-e2e/s130-physical-ui-toolbar-smoke.txt`.

## S131 packaged toolbar capture acceptance — 2026-08-30

- The exact installed ShotEye `Capture area` toolbar control accepted a click, launched the bundled selector, accepted a real HID area drag, restored the editor, and copied the resulting valid `600×500` PNG through ShotEye's own Copy path.
- Evidence: `artifacts/tauri-e2e/s131-toolbar-capture-success.txt` and `s131-toolbar-capture-success.png`.
- This closes the installed toolbar-to-selector-to-clipboard path for one display. Global shortcut, Finder-drop, secondary-display, Developer ID, Gatekeeper, and notarization gates remain separate.

## S132 packaged global shortcut acceptance — 2026-08-30

- The exact installed package routed the default `⌘⇧Y` shortcut while Finder was frontmost, launched the selector, cancelled with Escape, and restored the editor.
- The packaged `Record capture shortcut` control accepted `⌘⇧U`; the custom shortcut launched the selector while Finder was frontmost, and `Reset capture shortcut to default` restored a working `⌘⇧Y` binding.
- Evidence: `artifacts/tauri-e2e/s132-shortcut-acceptance.txt`. Shortcut conflict, alternate keyboard-layout, Finder-drop, secondary-display, Developer ID, Gatekeeper, and notarization gates remain separate.

## S135/S137 orientation and Finder drag-out hardening — 2026-08-30

- Verified the exact installed package after the native compositor orientation fix with a real area selection and ShotEye Copy path. The resulting `800×700` PNG is upright and has a valid PNG signature; evidence is `artifacts/tauri-e2e/s135-orientation-acceptance.txt` and `s135-current-orientation.png`.
- Fixed the native Finder drag handoff by passing the original WebView pointer position into AppKit, creating the synthetic event in window-base coordinates, and retaining the staged URL until the managed drag state is released at app shutdown. This prevents delayed IPC, coordinate drift, and Finder consumption from racing cleanup.
- The exact installed package passed an isolated Finder drop and produced a valid upright `800×700` `ShotEye Capture.png`; evidence is `artifacts/tauri-e2e/s137-finder-drop-acceptance.txt` and `s137-finder-drop/ShotEye Capture.png`.
- The refreshed local Apple Silicon DMG is `artifacts/releases/ShotEye_0.1.0_aarch64.dmg` with SHA-256 `061bd46e63bbc6cc3c24736e1dcbc60320f3365d183054f88fc7dfb9061ac657`. Local signing remains `ShotEye Local Development` without a TeamIdentifier; Developer ID, Gatekeeper, notarization, shortcut-conflict, alternate-layout, and secondary-display gates remain open.

## S90 stable local package identity — 2026-08-30

- Added a bounded non-interactive signing probe to `scripts/package_app.sh`. Local packaging opts into the installed `ShotEye Local Development` identity only when `codesign` can use its private key; otherwise it keeps the existing ad-hoc development fallback and prints an actionable warning.
- Tauri treats `ShotEyeSelector` as a bundled resource, so the package script now signs the selector first and re-signs the containing app. The installed app, main executable, and selector therefore share one stable local authority for evaluation installs and TCC continuity.
- S90 verification: full frontend suite 54/54, Rust suite 39/39, `cargo check`, shell syntax, `git diff --check`, stable-identity arm64 package, exact `/Applications/ShotEye.app` install, runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG byte/hash parity all pass.
- Evidence: `artifacts/tauri-e2e/s90-runtime-contract.txt`, `artifacts/tauri-e2e/s90-final-installed-verification.txt`, `artifacts/tauri-e2e/s90-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- This is local evaluation evidence, not a public release: the certificate has no TeamIdentifier, Gatekeeper/`spctl` acceptance is not proven, and physical selector drag, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display interaction, Developer ID signing, and notarization remain external gates.

## S91 capture-mode entry-point evidence — 2026-08-30

- Extended the real React `App` harness through the Window, Full screen, and Repeat last capture toolbar actions. Each action is asserted to use its shared native lifecycle and to commit a valid preview/status without duplicating capture logic.
- Updated the README's verification example to use a fresh report path and clarified that local packaging uses the stable `ShotEye Local Development` identity when its private key is available, with explicit ad-hoc fallback otherwise.
- S91 verification: focused capture harness 13/13 and the complete frontend suite 58/58. These component tests do not alter the production native adapter.
- Physical selector interaction, global shortcut invocation, Clipboard/Save/Finder drag, secondary-display capture, Developer ID signing, Gatekeeper, and notarization remain external gates.

## S92 startup readiness and canonical DMG provenance — 2026-08-30

- Fixed a startup ordering race where runtime-contract mode could signal Rust readiness before the asynchronous `capture-requested` listener was installed. Runtime-contract startup now awaits the listener's readiness promise, and the new regression fails before the fix and passes after it.
- Made `scripts/package_app.sh` atomically refresh `artifacts/releases/ShotEye_0.1.0_<arch>.dmg` from the just-created package output, then verify byte parity. `scripts/verify_app.sh` now rejects a requested or built DMG that differs from the canonical download artifact before mounting or reporting success.
- S92 verification: full frontend 58/58, Rust 39/39, `cargo check`, production build, shell syntax, `git diff --check`, stable-identity arm64 package/install, runtime contract, installed verification, mounted-DMG verification, canonical DMG parity, and a deliberate mismatched-DMG rejection all pass.
- Evidence: `artifacts/tauri-e2e/s92-runtime-contract.txt`, `artifacts/tauri-e2e/s92-final-installed-verification.txt`, `artifacts/tauri-e2e/s92-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- Developer ID/notarization and physical selector, shortcut, Clipboard/Save, Finder-drag, and secondary-display acceptance remain external gates.

## S93 session capture history — 2026-08-30

- Added an immutable, bounded session history model that keeps the eight most recent successful capture/import results within a 128 MiB encoded-data budget without mutating prior entries.
- Added a compact Recent captures strip with accessible restore buttons, dimensions, current-entry indication, and thumbnail previews. Restoring an entry resets annotations, crop state, and zoom so the editor returns to a coherent source-image state.
- History records only successful canonical image results from capture and image import; cancellation, malformed output, and failed operations do not create entries. The history is in-memory session state and is cleared on relaunch.
- S93 verification: focused App harness 14/14, full frontend 63/63 across 15 files, Rust 39/39, `cargo check`, production build, stable-identity arm64 package/install, runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG parity all pass.
- Evidence: `artifacts/tauri-e2e/s93-runtime-contract.txt`, `artifacts/tauri-e2e/s93-final-installed-verification.txt`, `artifacts/tauri-e2e/s93-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- Release preflight correctly fails closed without a configured Developer ID signer (`./scripts/package_app.sh --release`, exit 1). Physical selector/shortcut/export, secondary-display, Developer ID, Gatekeeper, and notarization acceptance remain external gates.

## S95 session history memory bound — 2026-08-30

- Added a 128 MiB encoded-data budget to the existing eight-entry session history. Newest-first insertion remains immutable; older entries are evicted when the payload budget is exhausted.
- Added deterministic helper coverage for byte-budget eviction using synthetic data URLs, avoiding a test that would need to allocate real screenshot-sized payloads.
- S95 verification: focused history tests 5/5, full frontend 64/64 across 15 files, Rust 39/39, `cargo check`, production build, stable-identity arm64 package/install, runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG parity all pass.
- Evidence: `artifacts/tauri-e2e/s95-runtime-contract.txt`, `artifacts/tauri-e2e/s95-final-installed-verification.txt`, `artifacts/tauri-e2e/s95-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- `cargo fmt --check` and `cargo clippy` could not run because the stable toolchain does not include those components. Public signing and physical macOS acceptance remain external gates.

## S96 native lint cleanup — 2026-08-30

- Installed the missing Rust `rustfmt` and `clippy` components locally and fixed the six available Clippy warnings without changing capture behavior: slice parameters, redundant returns/closures/borrows, and an explicit Tauri IPC argument-count allowance.
- S96 verification: Clippy clean, full frontend 64/64 across 15 files, Rust 39/39, `cargo check`, production build, stable-identity arm64 package/install, runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG parity all pass.
- `cargo fmt --check` still reports repository-wide pre-existing formatting drift in `src-tauri/src/lib.rs` and `macos_drag.rs`; no wholesale reformat was applied because it would rewrite unrelated WIP. Public signing and physical macOS acceptance remain external gates.

## S97 privacy-safe Redact annotation — 2026-08-30

- Added a first-class Redact annotation that shares the existing source-coordinate geometry, selection, translation, resize handles, undo/redo, crop, and revision-guarded export pipeline.
- The live editor renders Redact as an opaque black rectangle, and `renderAnnotation` uses `fillRect` with `#000000` for Copy, Save, Drag, and Crop composition. The annotation color control cannot accidentally turn a privacy mask into a translucent or outline-only mark.
- S97 verification: focused geometry/App Redact coverage 22/22, full frontend 67/67 across 15 files, Rust 39/39, `cargo check`, Clippy clean, production build, stable-identity arm64 package/install, runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG parity all pass.
- Evidence: `artifacts/tauri-e2e/s97-runtime-contract.txt`, `artifacts/tauri-e2e/s97-final-installed-verification.txt`, `artifacts/tauri-e2e/s97-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- Physical pointer redaction, Clipboard/Save/Finder acceptance, secondary-display capture, Developer ID signing, Gatekeeper, and notarization remain external gates.

## S98 session history privacy control — 2026-08-30

- Added an accessible `Clear history` control to the Recent captures surface. It removes all in-memory session history while preserving the currently displayed canonical image and leaving the editor actionable.
- The control is disabled during an active capture, uses the existing user-action status boundary, and does not introduce disk persistence or a new native storage permission.
- S98 verification: focused App coverage 16/16, combined Redact/App focused coverage 22/22, full frontend 68/68 across 15 files, Rust 39/39, `cargo check`, Clippy clean, production build, exact arm64 package/install, packaged runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG parity all pass.
- Evidence: `artifacts/tauri-e2e/s98-runtime-contract.txt`, `artifacts/tauri-e2e/s98-final-installed-verification.txt`, `artifacts/tauri-e2e/s98-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- Physical pointer capture/export, secondary-display interaction, Developer ID signing, Gatekeeper, and notarization remain external gates; `./scripts/verify_app.sh --release` correctly rejects this local-only identity.

## S99 permission denial before hide — 2026-08-30

- Moved the non-prompting Screen Recording preflight ahead of the native editor hide transition. A known-denied capture now returns the actionable permission message while leaving the editor visible and avoiding an unnecessary hide/restore cycle.
- Runtime-contract captures remain allowed to exercise the full hide/capture/restore path, and the existing capture activity guard still releases on every terminal result.
- S99 verification: focused Rust regression 1/1, full frontend 68/68 across 15 files, Rust 40/40, `cargo check`, Clippy clean, production build, exact arm64 package/install, packaged runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG parity all pass.
- Evidence: `artifacts/tauri-e2e/s99-runtime-contract.txt`, `artifacts/tauri-e2e/s99-final-installed-verification.txt`, `artifacts/tauri-e2e/s99-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- Physical permission-denial UI, pointer capture/export, secondary-display interaction, Developer ID signing, Gatekeeper, and notarization remain external gates; `./scripts/verify_app.sh --release` correctly rejects the local-only identity.

## S100 focus-driven permission refresh — 2026-08-30

- Added a consent-free `onFocusChanged` listener to refresh Screen Recording status whenever ShotEye becomes active again, including after the user returns from System Settings. Blur events are ignored so normal focus transitions do not issue unnecessary checks.
- Reused the existing native-operation guard and status epoch so a focus refresh cannot race an active capture/permission action or replace a newer user-owned status with a late response.
- S100 verification: focused App coverage 17/17, full frontend 69/69 across 15 files, Rust 40/40, `cargo check`, Clippy clean, production build, exact arm64 package/install, packaged runtime contract, strict installed verification, mounted-DMG verification, and canonical DMG parity all pass.
- Evidence: `artifacts/tauri-e2e/s100-runtime-contract.txt`, `artifacts/tauri-e2e/s100-final-installed-verification.txt`, `artifacts/tauri-e2e/s100-final-dmg-verification.txt`, `artifacts/tauri-e2e/s100-release-rejection.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- Physical permission-denial UI, pointer capture/export, secondary-display interaction, Developer ID signing, Gatekeeper, and notarization remain external gates; `./scripts/verify_app.sh --release` is still expected to reject the local-only identity.

## S101 packaged baseline and acceptance boundary — 2026-08-30

- Re-ran `scripts/verify_app.sh --launch --report artifacts/tauri-e2e/s101-baseline-installed-verification.txt` against the exact `/Applications/ShotEye.app` bundle. It passed one-process launch, strict bundle structure/signature, helper permission preflight, helper display-read, AppKit selector-event, geometry, mixed-DPI, crop-transform, mounted-DMG, and canonical-DMG parity checks.
- Confirmed the installed app and bundled selector are both signed by the stable local `ShotEye Local Development` identity. This is suitable for local TCC continuity, but it is not a Developer ID identity and does not satisfy Gatekeeper/notarization release gates.
- The physical acceptance boundary is recorded in `artifacts/tauri-e2e/s101-physical-acceptance-boundary.txt`: the desktop session was locked at the macOS login screen and `System Events` reported that assistive access was not allowed. No toolbar-click, pointer-drag, Clipboard/Save, or global-shortcut claim is made from this run.
- Next executable acceptance step: unlock the Mac, grant Accessibility to the exact installed ShotEye identity, then run the physical toolbar/selector/shortcut/export matrix against `/Applications/ShotEye.app`.

## S102 package refresh and reproducibility — 2026-08-30

- Rebuilt the current source with the local stable signing identity, refreshed the canonical arm64 DMG, and installed the exact bundle at `/Applications/ShotEye.app`.
- Re-ran the installed verifier and mounted-DMG verifier. Both pass strict structure/signature, one-process launch, helper permission preflight, Core Graphics display-read, AppKit selector-event, geometry, mixed-DPI, crop-transform, and DMG parity checks.
- Evidence: `artifacts/tauri-e2e/s102-final-installed-verification.txt`, `artifacts/tauri-e2e/s102-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- This sprint does not claim physical toolbar, selector drag, shortcut, Clipboard/Save/Finder-drag, or secondary-display acceptance because the desktop session is locked and Accessibility automation is unavailable. Developer ID signing, Gatekeeper, and notarization remain release gates.

## S103 independent Accessibility UI smoke harness — 2026-08-30

- Added `scripts/verify_ui_smoke.sh`, which launches/reuses `/Applications/ShotEye.app`, asserts exactly one canonical `shoteye` process, requires strict app signature validation, and checks the product toolbar's accessible control names plus the `ShotEye`, `File`, `Capture`, `Edit`, and `Help` menus through `System Events`.
- The harness writes a clear `PASS`, `FAIL`, or `BLOCKED` report and returns `2` when Accessibility or an unlocked desktop is unavailable. It never treats a blocked automation attempt as a physical acceptance pass.
- Current host result: `BLOCKED` with `osascript is not allowed assistive access (-25211)`, recorded in `artifacts/tauri-e2e/s103-physical-ui-smoke.txt` and `artifacts/tauri-e2e/s103-ui-smoke-command.txt`.
- The harness covers discoverability and single-instance UI structure; actual selector drag, shortcut invocation, Clipboard/Save/Finder-drag, and secondary-display behavior still require a later unlocked Accessibility/TCC run.

## S105 representative toolbar click acceptance — 2026-08-30

- Extended `scripts/verify_ui_smoke.sh` to click `Rectangle`, `Select`, `Pin ShotEye`, and `Unpin ShotEye` after checking the complete accessible toolbar/menu surface. These actions do not capture, open dialogs, request privacy access, or write files/clipboard data.
- The current host result is correctly `BLOCKED` with exit `2` because `System Events` reports `osascript is not allowed assistive access (-25211)`. The click assertions were not run and are not represented as passed.
- Evidence: `artifacts/tauri-e2e/s105-physical-ui-smoke.txt` and `artifacts/tauri-e2e/s105-ui-smoke-command.txt`.

## S106 single-flight permission refresh — 2026-08-30

- Added a frontend in-flight guard around the focus-triggered, non-prompting `screen_capture_permission_status` command. Repeated focus notifications while one status request is pending are coalesced; terminal status still uses the existing epoch and the guard is released in `finally`.
- RED→GREEN evidence: the focused App test was `17 passed, 1 failed` before the fix because two focus events created three total status calls; after the fix it passes `19/19`, including rejection-and-retry coverage. The full frontend suite passes `71/71`.
- Rebuilt/installed the fixed exact arm64 package. Rust 40/40, `cargo check`, Clippy, installed-package verification, mounted-DMG verification, and canonical DMG parity pass.
- The post-install Accessibility smoke run remains correctly `BLOCKED` with `-25211` because this desktop is locked/assistive access is denied; the representative click phase was not claimed.
- Evidence: `artifacts/tauri-e2e/s106-final-installed-verification.txt`, `artifacts/tauri-e2e/s106-final-dmg-verification.txt`, `artifacts/tauri-e2e/s106-physical-ui-smoke.txt`, and `artifacts/tauri-e2e/s106-ui-smoke-command.txt`.

## Definition of done

The app launches as one active instance, toolbar actions receive clicks, capture permissions are handled, and the arm64 package opens from a fresh extraction.

## Latest evaluation

Fresh ZIP extraction now launches with `NSRunningApplication.isActive == true` after repeated launch activation timing guards. The current arm64 package is installed at `/Applications/ShotEye.app`, runs as one exact `shoteye` process, passes strict local signature validation, and has fresh runtime PNG evidence under `artifacts/tauri-e2e/`.

S61 verification also passes the hidden-editor capture lifecycle unit suite, the full 41-test frontend suite, the 34-test Rust suite, exact arm64 installation, and mounted-DMG payload validation. S62 adds the show-failure/focus-recovery edge and the full frontend suite now passes 42 tests. The current local DMG is `tauri-app/src-tauri/target/aarch64-apple-darwin/release/bundle/dmg/ShotEye_0.1.0_aarch64.dmg`; physical drag capture and Developer ID/notarization remain release gates.
The exact bundled helper also passes non-prompting permission and display-read checks, and a direct system fullscreen capture returns a valid 2940×1912 PNG. This execution environment renders that artifact all black, so it is not treated as visible-pixel or interactive-selector proof.
S64 additionally proves the native selector interaction reducer in the installed app and exact mounted DMG, including reverse-drag normalization, undersized-drag reset, and cancellation reset.

## Tauri diagnostic track — 2026-08-25

- A separately identified macOS Tauri package now proves the alternative UI stack is interactive.
- The packaged WebKit frontend loads, every visible toolbar button is discoverable through macOS Accessibility, and each action reaches a Rust command.
- Native macOS area capture now runs through Rust, previews a captured PNG, and reports cancellation/errors without hanging.
- Copy uses a separate macOS clipboard operation and Save opens the native macOS save panel; a successful automated drag-selection acceptance test remains next.
- The packaged Tauri app prevents duplicate instances and registers `⌘⇧Y` as its default global area-capture shortcut.
- The Tauri editor now stores annotations in source-image coordinates and rasterizes them only at Copy/Save into the Rust-owned canonical capture record.
- Packaged cancellation testing verifies the editor restores after the native selector ends; its Tauri capability explicitly grants the frontend hide/show/focus lifecycle.
- Packaged acceptance testing proves Open JPEG → annotate → Copy → Paste → Save produces a valid 1240×1754 PNG with the annotation preserved.
- The Tauri capture adapter preflights native Screen Recording access before launching the interactive selector. This prevents repeated consent prompts for a denied or stale permission record; public-beta persistence still requires Developer ID signing.
- Local self-signed signing was evaluated and rejected: although strict code-signature validation passed, the certificate-signed package launched a blank WebKit editor while the ad-hoc control rendered normally. Local builds remain ad-hoc; public-beta delivery requires a real Developer ID identity plus notarization.
- Area capture explicitly starts macOS's selection mode in unified display space and never applies main-display or display-target restrictions. A physical secondary-display acceptance run remains required when that hardware is connected.
- The capture shortcut starts as `CommandOrControl+Shift+Y`, can be recorded in the editor, and only replaces the previous registration after the native global-shortcut manager accepts it. The chosen shortcut persists locally for the next editor launch.
- Area capture now prefers the bundled arm64 AppKit selector. It paints one selection surface across the connected display union, composites the selected display pixels into a PNG, and returns Escape/cancel without invoking a second selector. The existing `screencapture` adapter remains the fallback when the bundled helper is unavailable.
- Permission recovery exposes two distinct actions: one explicit consent request and one direct route to macOS Screen Recording settings. This prevents an unavailable-permission status from leaving the user without an actionable next step.
- The explicit Permissions control requests one-time macOS consent. Packaged verification proves Full screen capture and Repeat Last Capture return a 2940×1912 preview after the current installed build is granted access.
- The release editor must not expose internal framework or diagnostic branding; user-facing title, macOS window/menu name, bundle, and empty state use the product name, ShotEye.
- The release editor uses macOS's native titlebar controls only; it must not render a second in-WebView traffic-light row.
- Selected rectangles expose four corner resize handles and selected arrows expose start/end handles. Resize previews remain in source-image coordinates and commit as one undoable edit on release.
- Crop normalizes forward, reverse, and edge-clamped drags in source-image coordinates. Packaged JPEG open → Crop → Reset → Copy/Save acceptance produced a valid cropped PNG.
- Annotation history supports Undo and Redo for added marks. A new mark or Clear invalidates a stale redo branch, and packaged Rectangle → Undo → Redo acceptance is verified.
- Configured shortcut labels and registration success messages use macOS notation (for example, `⌘⇧Y`) rather than internal global-shortcut syntax.
- Select can target topmost annotations, drag to move them, resize rectangles/arrows, and Delete/Backspace removes the selection with Undo recovery.
- Editor shortcuts use familiar macOS chords (`⌘Z`, `⌘⇧Z`, `⌘O`, `⌘V`, `⌘C`, and `⌘S`) without hijacking text fields or the capture-shortcut recorder.

## S29 capture reliability hardening

- The bundled AppKit selector uses a key-capable borderless panel, cancels cleanly when it loses activation, and orders itself out before display pixels are captured.
- Multi-display composition uses a top-left logical coordinate system so selections spanning vertically arranged displays keep their visual order.
- A failed, cancelled, denied, or malformed capture no longer erases the last valid Rust-owned image while the editor still displays it.
- Native selector exit codes distinguish cancellation from failure; a helper-specific permission/launch failure can fall back to macOS's system selector without opening a second selector after cancellation.
- The packaged macOS plist includes `NSScreenCaptureUsageDescription`, and its advertised minimum macOS version matches the bundled Swift helper.
- The latest local package is installed at `/Applications/ShotEye.app`, strict-verifiable, and launches as one ShotEye process. Physical capture success and Developer ID continuity remain unproven external gates.
- The selector-to-capture handoff now keeps the overlay alive during the valid drag handoff and only cancels on deactivation before selection; a private per-run temporary directory is cleaned on success, failure, cancellation, or early exit.
- Latest evidence: installed and built helper SHA-256 values match (`b78886ee93b49b497e2632ae5aa925bb23641abb7dfac6464033ace23dac2df2`), strict app/helper verification passes, and the runtime screen artifact is `artifacts/tauri-e2e/s29-shoteye-runtime.png` (2940×1912 PNG).
- Window capture is now exposed through `capture_window` and `screencapture -i -J window`; it shares the hide/restore, preflight, validation, repeat-mode, and Rust-owned image-state contract.
- ShotEye performs a non-prompting Screen Recording preflight at editor startup and shows the current permission state before the first capture attempt.
- Pin toggles the native Tauri window's always-on-top state and reports success or failure without claiming the state until the OS call completes.
- Clipboard Copy and image import stage through private per-operation temporary directories and clean them on all normal and early-return paths.
- Save supports PNG, JPEG, and TIFF output selected by the filename extension while keeping clipboard Copy as canonical PNG.
- The editor exposes a native AppKit Drag action that stages the current canonical PNG in a private per-drag location and starts a Finder-compatible file drag on the macOS main thread.
- Drag staging is retained in managed Rust state for the lifetime of the app so Finder never receives a path whose file was deleted before the drop.

## S35 native Finder drag-out

- The available community `tauri-plugin-dragout` dependency was audited and rejected for direct adoption: its examples and command namespace are inconsistent, its default implementation is archive-oriented, and its default promise callback does not materialize a dropped file.
- ShotEye now uses a small in-process Cocoa/AppKit bridge instead. The `Drag` control writes the latest canonical annotated PNG to a private `0700` directory and starts `NSView.beginDraggingSessionWithItems:event:source:` using an `NSURL` file item.
- Drag failures return an actionable status and do not affect the canonical capture, annotations, Copy, or Save state.
- Focused Rust coverage verifies the product-named PNG staging path and private directory permissions; a physical drag to Finder remains an operator-gated acceptance test.

## S35 hardening follow-up

- Native drag startup now synthesizes a fresh AppKit mouse-down event from the current macOS pointer location after the Tauri main-thread hop, avoiding stale `NSApp.currentEvent` failures.
- The drag image is rendered from the staged PNG, and the native source removes its private file and directory when AppKit reports that the drag session ended.
- React export preparation is serialized across background drag refreshes, Copy, and Save, with revision checks preventing an older annotation render from being advertised as ready for Drag.
- Latest package evidence: `/Applications/ShotEye.app` launches as one process, strict signature verification passes, the helper hash is `b78886ee93b49b497e2632ae5aa925bb23641abb7dfac6464033ace23dac2df2`, and `artifacts/tauri-e2e/s35b-shoteye-runtime.png` is a valid 2940×1912 PNG.

## S36 product identity and capture hardening

- Root packaging now selects the host's explicit Tauri target (`aarch64-apple-darwin` or `x86_64-apple-darwin`) and validates both packaged Mach-O binaries before reporting success.
- Root launch verification checks the full executable command path and no longer uses broad process termination; the legacy Swift package is isolated under `legacy-swift/`.
- Shortcut readiness is guarded by one mutex and the frontend reports readiness only after the native event listener is registered, preventing an early global shortcut from being lost.
- Native shortcut recording preserves Command versus Control and accepts function, punctuation, and numpad keys. Capture shortcuts are ignored while the recorder is active.
- Crop drafts are cleared on tool changes and pointer cancellation. Drag preparation can retry from the first click and a delayed AppKit callback cannot start against a cleaned staging file.
- The bundled selector rejects any selection where one intersecting display could not be read instead of returning a partial transparent composite.
- Tool selection is local editor state and no longer sends a diagnostic IPC round trip; capture, permission, and export statuses cannot be overwritten by a delayed framework acknowledgement, and the shipped footer contains only user-facing status and shortcuts.

## S38 native executable identity

- The Rust package/library, npm package, packaged executable, and root verification/log predicates use `shoteye`, matching the ShotEye product name.
- Installing a renamed bundle moves the previous exact app to Trash before copying the new bundle, preventing stale `Contents/MacOS/tauri-app` files from surviving an in-place update.

## S39 release packaging gate

- Local packaging remains explicitly ad-hoc for development and evaluation.
- `scripts/package_app.sh --release` requires a complete `Developer ID Application` identity and Apple notarization credentials before building, then validates strict signing, Gatekeeper acceptance, and a stapled notarization ticket.
- The release gate rejects the available `ShotEye Local Development` certificate instead of silently producing a public-looking but non-distributable DMG.

## S40 helper Screen Recording preflight

- The bundled AppKit selector exposes a non-prompting `--check-permission` probe so Rust can test the helper executable before showing an overlay.
- When the helper reports its reserved permission-denied exit code, Rust skips that helper attempt and uses the system selector fallback; any helper exec failure uses the same fallback, while cancellation and unexpected helper exit codes retain their existing semantics.
- This prevents a helper-specific TCC mismatch from flashing a second selector or repeatedly reopening consent while preserving the single `capture_area` command boundary.
- The fresh arm64 package contains the probe-enabled helper, launches as one exact `shoteye` process, and passes strict local signature validation. Physical drag-selection and notarized release signing remain external gates.

## S41 startup shortcut recovery

- ShotEye treats a persisted custom capture shortcut as a preference, not proof that the shortcut is still available.
- If the saved shortcut is rejected during startup, the editor clears the stale preference, keeps the native default `⌘⇧Y` active, and displays the effective fallback instead of repeatedly retrying or advertising an inactive chord.
- A user-initiated replacement failure continues to preserve the currently active shortcut and reports the registration error without overwriting the preference.

## S42 export freshness hardening

- Copy, Save, and Drag now prepare exports from latest synchronous refs instead of relying on a possibly stale React render closure.
- Each async export preparation is checked against the capture/annotation revision; if the image changes during preparation, the work retries from the new revision and fails with an actionable message if it never stabilizes.
- Background Drag preparation remains serialized behind Copy and Save, and the ready state cannot advertise an older annotated PNG.
- Focused proof covers stable preparation, one revision-change retry, and bounded failure for perpetual changes. The full frontend suite is green at 31 tests, Rust coverage is green at 24 tests, and the arm64 package was rebuilt and installed.
- S42 evidence: `/Applications/ShotEye.app` has one exact product process, no stale `tauri-app` executable, strict signature verification passes, the helper preflight exits 0, and `artifacts/tauri-e2e/s42-shoteye-runtime.png` is a valid 2940×1912 PNG.
- Physical selector interaction, secondary-monitor capture, Finder drop, global shortcut delivery, and Developer ID/notarized release remain external acceptance gates.

## S43 installed-package verification

- Added `scripts/verify_app.sh` as the single install-level verifier for the exact `/Applications/ShotEye.app` bundle.
- The verifier checks the expected ShotEye bundle identifier/executable, arm64/x86_64 architecture, bundled helper, strict signature, stale executable absence, built/installed binary parity, DMG presence, helper permission preflight, and optional PNG header/dimensions.
- `script/build_and_run.sh --verify` now delegates to the same verifier, preventing drift between local smoke checks and release evidence.
- The installed package plus `artifacts/tauri-e2e/s42-shoteye-runtime.png` passed the new gate. The gate intentionally does not claim physical pointer capture or Developer ID/notarization.

## S44 exclusive export actions

- Copy, Save, and Drag now share one in-flight guard in the editor. A second action receives an actionable status instead of starting while the first native export is pending.
- The guard covers preparation, the Save dialog, native clipboard/file export, and drag startup, and is released on success, cancellation, or failure.
- Focused coverage proves a pending action blocks a second action and that a rejected action releases the guard for the next operation. The full frontend suite is green at 33 tests.
- The current arm64 package was rebuilt, installed as `/Applications/ShotEye.app`, verified by the shared install gate, and accompanied by `artifacts/tauri-e2e/s44-shoteye-runtime.png` (2940×1912 PNG).
- Physical selector interaction, secondary-monitor capture, Finder drop, global shortcut delivery, and Developer ID/notarized release remain external acceptance gates.

## S45 unified native-operation lane

- Capture now shares the same exclusive operation guard as Copy, Save, and Drag, so a user-triggered native capture cannot overlap an in-flight export.
- The guard is acquired synchronously before asynchronous work begins and released in `finally`; rapid toolbar clicks and early global-shortcut delivery receive a clear busy status instead of starting a competing native operation.
- Focused exclusive-action coverage remains green, along with the full 33-test frontend suite and 24-test Rust suite. The arm64 package was rebuilt, installed, and checked by the shared verifier.
- S45 evidence: `/Applications/ShotEye.app` is one exact `shoteye` process, the helper preflight exits 0, and `artifacts/tauri-e2e/s45-shoteye-runtime.png` is a valid 2940×1912 PNG.
- Physical selector interaction, secondary-monitor capture, Finder drop, global shortcut delivery, and Developer ID/notarized release remain external acceptance gates.

## S46 native menu command surface

- The WebView installs a product-branded macOS menu with File, Capture, Edit, and Help groups.
- Menu actions delegate through synchronous current React handler refs, so Open/Paste/Copy/Save, capture modes, annotation history, permission recovery, and reset actions cannot use stale image state from the menu-install render.
- File and Edit menu accelerators use the same platform-neutral `CmdOrCtrl+…` syntax as the existing shortcut boundary; Capture area remains discoverable without duplicating the global shortcut registration.
- The menu model has focused coverage for unique command IDs and the primary workflow action set. The production frontend, Rust suite, arm64 package, exact install, and shared verifier pass.
- Physical menu-click acceptance remains unclaimed because the current session has no Accessibility-enabled desktop harness. Developer ID signing, Gatekeeper acceptance, and notarization remain external release gates.

## S47 transactional display selection

- The AppKit selector now checks that every logical slab of a requested area is covered by connected display frames before reading pixels. A drag through a physical gap exits with an actionable status instead of returning a transparent-hole PNG.
- Rust launches the bundled selector only when its non-prompting helper probe returns an affirmative result; denied and inconclusive probes use the tested system-selector fallback.
- Exit code `4` identifies a display-gap rejection, while exit codes `2` and `3` retain cancellation and helper-permission semantics.
- The helper geometry self-test is run by the install verifier. The full frontend suite, 25-test Rust suite, Swift helper build, arm64 package, exact install, permission probe, geometry self-test, and PNG evidence pass.
- Mixed-DPI normalization and physical cross-display pointer acceptance remain explicitly documented follow-up gates; Developer ID signing, Gatekeeper acceptance, and notarization remain external release gates.

## S48 bounded native capture lifecycle

- `screencapture` and the bundled selector are spawned as owned children and polled with a five-minute deadline instead of using an unbounded blocking `status()` call.
- A timeout kills and reaps the child, returns a dedicated actionable status, and lets the frontend `finally` path restore/focus ShotEye and release the shared native-operation guard.
- Helper launch errors still use the system-selector fallback, but a timed-out helper is a capture failure and cannot trigger a second overlay.
- Focused timeout coverage, the full frontend suite, the 26-test Rust suite, Swift helper build, arm64 package, exact install, verifier, and PNG evidence pass.
- Physical selector/menu interaction, mixed-DPI proof, and Developer ID/notarized release remain external gates.

## S49 status and package evidence hardening

- Startup permission, shortcut, menu, and listener promises now capture a status epoch and commit only while that epoch is current. User-triggered Open, Paste, Permissions, Settings, Pin, shortcut replacement, capture, and export actions advance the epoch before awaiting native work.
- Background Drag prewarming no longer calls `store_rendered_capture`; it caches a revision-tagged data URL in the WebView and the exclusive Copy/Save/Drag lane publishes it to Rust only when the user commits an export.
- The helper `--check-permission` probe now uses the same owned child timeout/kill/reap wrapper as capture, with a two-second deadline and system-selector fallback on timeout.
- `scripts/package_app.sh` uses Tauri's app bundle target followed by direct `hdiutil` DMG creation, and `scripts/verify_app.sh --dmg <path>` mounts the disk image read-only and verifies its embedded ShotEye bundle.
- Focused proof: 36 frontend tests, 27 Rust tests, TypeScript/Vite build, Swift helper build, arm64 package, exact installed app verification, and mounted DMG payload verification pass. Physical pointer/menu/shortcut acceptance and Developer ID/notarization remain open.

## S50 mixed-DPI compositor evidence

- Extracted the native display compositor into a testable pure function while preserving the existing `capture_area` command and multi-monitor selection behavior.
- Made the compositor's pixel format explicit RGBA and disabled interpolation so a 1× source beside a 2× source has deterministic nearest-neighbor output at the selected maximum scale.
- Added a permission-free executable self-test that composes synthetic 1×/2× display images, verifies the expected 200×160 output, checks the seam at every column, and rejects transparent or incorrectly colored output pixels.
- The install verifier now runs both the geometry and mixed-DPI compositor self-tests for the exact installed app and exact mounted DMG payload.
- S50 evidence: 11 frontend files/37 tests, 27 Rust tests, Swift helper build and self-tests, arm64 package, one installed process, exact DMG payload verification, and reports at `artifacts/tauri-e2e/s50-shoteye-verification.txt` and `artifacts/tauri-e2e/s50-dmg-verification.txt`.
- The runtime PNG is structurally valid at 2940×1912 but visually black in this capture environment; physical area dragging, secondary-display capture, Finder drag, and Developer ID/notarized release remain open.

## S51 compositor coordinate hardening

- Replaced implicit `CGRect.integral` source cropping with an explicit floor-min/ceil-max backing-pixel policy.
- Applied the same policy to compositor destination edges so fractional display seams cannot create an uncovered output column or silently shift a crop boundary.
- Extended the permission-free native self-test with top/bottom color bands, a fractional selection origin and width, exact 201×161 output dimensions, seam ownership, alpha coverage, and a full output-pixel scan.
- Rebuilt and installed the arm64 package; the installed bundle and exact mounted DMG both pass geometry, mixed-DPI, identity, architecture, parity, signature, helper, and artifact checks.
- S51 evidence is under `artifacts/tauri-e2e/s51-shoteye-verification.txt` and `artifacts/tauri-e2e/s51-dmg-verification.txt`; the runtime artifact remains a structurally valid but visually black 2940×1912 PNG in this environment.

## S52 capture-boundary verification

- Extracted the native display crop transform into a pure helper used by the production selector path.
- Added a top-row-first synthetic `CGImage` crop test for upper and lower display selections, including exact output dimensions, expected backing rectangles, orientation, and opaque pixels.
- Added `--self-test-crop-transform` to the bundled helper and the install verifier, so the exact installed app and exact mounted DMG exercise geometry, mixed-DPI composition, and crop behavior.
- Bounded the native `/usr/bin/open` Screen Recording settings action with the existing owned-child timeout path and an actionable timeout message.
- S52 evidence: 37 frontend tests, 27 Rust tests, Swift helper self-tests, arm64 package, one installed process, exact DMG payload verification, and reports at `artifacts/tauri-e2e/s52-shoteye-verification.txt` and `artifacts/tauri-e2e/s52-dmg-verification.txt`.
- Physical area/window/secondary-display interaction, Finder drag, and Developer ID/notarized release remain open; the runtime screen artifact is structurally valid but black in this environment.

## S54 startup shortcut conflict recovery

- Default global-shortcut registration is best-effort during Tauri startup, so another app owning `⌘⇧Y` cannot abort the editor launch.
- Rust tracks whether the current shortcut is actually registered and retries the same value when the frontend reapplies startup configuration.
- Explicit replacements remain transactional: ShotEye registers the candidate first and retains the active shortcut if replacement fails.

## S55 canonical installed-bundle runner

- The root `script/build_and_run.sh` now installs the just-built arm64 bundle at `/Applications/ShotEye.app` before opening or verifying it.
- A prior installed bundle is moved to a unique recoverable temporary backup, so stale Launch Services and TCC targets cannot remain the active test target and the replacement remains recoverable.
- `run`, `--logs`, and `--verify` all use the same installed path; the build-tree bundle is no longer launched as a separate permission identity.
- Shell syntax, invalid-argument handling, packaging, exact installed-bundle verification, and mounted-DMG verification are the S55 evidence gates.
- Physical capture, global shortcut delivery, Finder drag, and Developer ID/notarization remain external acceptance gates.

## S56 native display-read evidence

- The bundled AppKit selector now exposes a noninteractive `--self-test-display-read` mode that runs Core Graphics Screen Recording preflight and reads the main display without opening an overlay or requesting consent.
- The installed-package verifier and mounted-DMG verifier run this test after the helper permission probe, proving that the exact packaged helper can obtain real display pixels under its current TCC identity.
- This evidence is intentionally narrower than a physical area drag: it does not claim pointer selection, secondary-display selection, or Copy/Save acceptance.
- S56 evidence is recorded in `artifacts/tauri-e2e/s56-shoteye-verification.txt` and `artifacts/tauri-e2e/s56-dmg-verification.txt`, including the actual preflight and display-read exit codes for each exact helper.

## S57 permission-action concurrency and stale-status guard

- Toolbar and native-menu Screen Recording permission actions now share one async guard, so repeated activation cannot issue concurrent macOS permission requests or open settings during a pending request.
- The permission controls visibly disable while either permission action is pending, and the request control reports `Requesting…` during the native consent boundary.
- Permission success and failure messages are status-epoch guarded, so a later capture, import, or other user action cannot be overwritten by a delayed permission result.
- S57 evidence: 37 frontend tests, 28 Rust tests, TypeScript/Vite build, arm64 package, exact install, installed-app verification, and mounted-DMG verification pass. Reports are at `artifacts/tauri-e2e/s57-shoteye-verification.txt` and `artifacts/tauri-e2e/s57-dmg-verification.txt`.
- Physical permission-dialog, area-drag, secondary-display, Copy/Save, Finder-drag, shortcut, and Developer ID/notarized-release acceptance remain open.

## S58 canonical artifact verification

- The install verifier now derives the expected DMG filename from the host architecture and validates that exact package instead of selecting an arbitrary older `ShotEye_*.dmg`.
- The installer now validates the source bundle with strict deep code-signature verification before stopping the current process or replacing `/Applications/ShotEye.app`.
- S58 evidence: shell syntax, full frontend tests, exact installed-app verification, and exact mounted-DMG verification pass. Reports are at `artifacts/tauri-e2e/s58-shoteye-verification.txt` and `artifacts/tauri-e2e/s58-dmg-verification.txt`.
- Physical desktop interaction, exact TCC continuity across rebuilds, and Developer ID/notarized distribution remain open.

## S65 atomic export writes

- Save now encodes the requested PNG, JPEG, or TIFF completely before touching the destination path.
- The encoded bytes are written to a unique hidden file beside the destination, synced, and atomically renamed into place so an interrupted export cannot leave a partial user file.
- Existing Save format selection and canonical PNG Copy behavior are unchanged.
- S65 evidence: 42 frontend tests, 35 Rust tests, TypeScript/Vite build, Swift helper build, exact arm64 package/install, strict signature validation, installed-app verification, and mounted-DMG verification pass. Reports are at `artifacts/tauri-e2e/s65-shoteye-verification.txt` and `artifacts/tauri-e2e/s65-dmg-verification.txt`.
- Physical Copy/Save interaction, secondary-display selection, Finder drag, and Developer ID/notarized release remain external acceptance gates.

## S68 toolbar interaction affordances

- Shared toolbar buttons now use a 40px minimum hit target and a high-contrast `:focus-visible` ring so keyboard and assistive navigation have a stable visual focus state.
- Hover styling remains separate from focus styling, preserving pointer feedback without removing the focus indicator.
- S68 evidence: 42 frontend tests, 35 Rust tests, TypeScript/Vite build, shell syntax and diff checks, exact arm64 package/install, strict signature validation, installed-app verification, and mounted-DMG verification pass. Reports are at `artifacts/tauri-e2e/s68-shoteye-verification.txt` and `artifacts/tauri-e2e/s68-dmg-verification.txt`.
- Physical toolbar activation, area drag, Copy/Save, shortcut invocation, Finder drag, and Developer ID/notarized release remain external acceptance gates.

## S69 stable toolbar iconography

- Replaced platform-dependent Unicode toolbar glyphs with consistent inline SVG icons for Open, Paste, Copy, Save, Drag, Repeat, Pin, Window, and Full screen.
- Icons are decorative and remain paired with the existing visible labels and accessible button names; the action and keyboard boundaries are unchanged.
- S69 evidence: 42 frontend tests, 35 Rust tests, TypeScript/Vite build, shell and diff checks, exact arm64 package/install, strict signature validation, installed-app verification, and mounted-DMG verification pass. Reports are at `artifacts/tauri-e2e/s69-shoteye-verification.txt` and `artifacts/tauri-e2e/s69-dmg-verification.txt`.
- Physical toolbar activation, area drag, Copy/Save, shortcut invocation, Finder drag, and Developer ID/notarized release remain external acceptance gates.

## S70 bounded clipboard operations

- Clipboard image import and Copy now run their AppleScript helper through the same owned, killable child lifecycle used by capture and settings actions.
- A hung clipboard helper is stopped after a bounded ten-second deadline, temporary staging is cleaned by the existing RAII path, and Copy reports an actionable timeout while releasing the frontend operation lane.
- S70 evidence: 42 frontend tests, 35 Rust tests, TypeScript/Vite build, shell and diff checks, exact arm64 package/install, strict signature validation, installed-app verification, and mounted-DMG verification pass. Reports are at `artifacts/tauri-e2e/s70-shoteye-verification.txt` and `artifacts/tauri-e2e/s70-dmg-verification.txt`.
- Physical clipboard paste, Copy, Save, drag-out, area drag, shortcut invocation, and Developer ID/notarized release remain external acceptance gates.

## S71 latest-revision Save ordering

- Save now opens the user-controlled destination dialog before preparing the rendered export.
- Annotation edits made while the dialog is open are therefore included in the final revision preparation, and the existing stable-revision guard still protects the native Save boundary.
- S71 evidence: 42 frontend tests, 35 Rust tests, TypeScript/Vite build, explicit Save-order assertion, diff checks, exact arm64 package/install, strict signature validation, installed-app verification, and mounted-DMG verification pass. Reports are at `artifacts/tauri-e2e/s71-shoteye-verification.txt` and `artifacts/tauri-e2e/s71-dmg-verification.txt`.
- Physical Save dialog, annotated export, area drag, shortcut, Finder-drag, and Developer ID/notarized release acceptance remain external gates.

## S72 single supported product layout

- Archived the stale root `dist/Shotser.app` bundle under `legacy-swift/archived/Shotser.app`; the supported launch target remains `/Applications/ShotEye.app` from the Tauri package.
- Packaging and verification now fail closed when any `.app` bundle appears directly under the repository root `dist/` directory, preventing stale duplicate products from being launched accidentally.
- S72 evidence: stale bundle identity inspection, recoverable archive move, shell syntax, exact arm64 package/install, strict signature validation, installed-app verification, and mounted-DMG verification pass. The active process is `/Applications/ShotEye.app/Contents/MacOS/shoteye`.
- Physical area drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarized release acceptance remain external gates.

## S73 duplicate-app guard verification

- Revalidated the current installed package after S72: `/Applications/ShotEye.app` is the only supported ShotEye launch target, while the historical `Shotser.app` remains outside the root build directory.
- Negative tests proved both package and verification scripts reject a temporary `.app` placed directly under root `dist/`; the probe was removed after the test.
- S73 evidence: exact installed-app verification and mounted-DMG verification pass with arm64 identity, strict signature, helper permission/display-read/geometry/compositor/crop/selection self-tests, and one active ShotEye process. Report: `artifacts/tauri-e2e/s73-shoteye-verification.txt`.
- Physical area drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarized release acceptance remain external gates.

## S74 permission-category clarity

- Permission status and recovery messages now name macOS's `Screen & System Audio Recording` category and explain that ShotEye captures screen pixels only and does not record system audio.
- `NSScreenCaptureUsageDescription` carries the same screen-only explanation.
- The focused Rust regression protects the wording while the existing non-prompting preflight continues to prevent repeated consent sheets during capture.
- S74 evidence: 42 frontend tests, 35 Rust tests, TypeScript/Vite build, exact arm64 package/install, strict signature validation, helper self-tests, mounted-DMG verification, and stable release-artifact hash parity.
- Physical permission-dialog, area-drag, Copy/Save, shortcut, Finder-drag, and Developer ID/notarized release acceptance remain open.

## S75 async crop stale-result invalidation

- Crop preparation now snapshots the current image through synchronous refs and captures an image-edit revision before any asynchronous decode or native persistence.
- Reset, image import, and every annotation-history mutation advance that revision synchronously, so a delayed crop cannot replace a newer image or annotation state.
- The crop result is checked after image preparation, immediately before native canonical storage, and again before React state commit; stale work exits without changing the visible editor state.
- S75 evidence: focused crop tests (5), full frontend suite (44), TypeScript/Vite build, Rust suite (36), arm64 package/install, strict installed-app verification, refreshed DMG hash parity, and mounted-DMG verification pass.
- App-level controllable async interleaving coverage, physical capture/export interaction, secondary-display selection, and Developer ID/notarization remain open.

## S76 AppKit selector event evidence

- The bundled native selector now runs a permission-free AppKit event self-test in addition to its pure gesture reducer checks.
- Synthetic `NSEvent` mouse-down, drag, and mouse-up messages exercise the real `SelectionView` handlers for forward and reverse selections; a synthetic Escape key event verifies cancellation callback delivery and interaction cleanup.
- The self-test verifies the panel is key-capable and the selection view accepts first responder status without showing a selector overlay or reading display pixels.
- S76 evidence: selector compilation and the bundled reducer/AppKit event self-test pass; 44 frontend tests, 36 Rust tests, exact arm64 package/install, strict installed-app verification, refreshed DMG hash parity, and mounted-DMG verification pass.

## S77 nested-helper release integrity — 2026-08-30

- Release packaging now validates the bundled `ShotEyeSelector` Developer ID authority and requires its Team ID to match the outer ShotEye app before Gatekeeper or notarization checks run.
- Package verification reports the selector reducer/AppKit event self-test exit code instead of emitting an unconditional textual pass marker.
- S77 evidence: shell syntax, ad-hoc package/install verification, mounted-DMG verification, and the guarded release preflight pass; the available local certificate is self-signed and is correctly rejected as a public-release signer.
- Physical pointer selection, Copy/Save, shortcut, secondary-display, Finder-drag, and Developer ID/notarization acceptance remain open.

## S78 capture/single-instance handoff — 2026-08-30

- The Rust capture boundary now owns an activity guard across area, window, fullscreen, and repeat capture commands.
- A second ShotEye launch no longer reveals or focuses the editor while the first instance is intentionally hidden for native selection; the existing capture completion path restores and focuses it after the guard is released.
- Overlapping native capture requests return an actionable busy result and cannot create a competing selector.
- S78 evidence: the new Rust overlap/RAII regression, full Rust/frontend checks, exact arm64 package/install, strict installed-app verification, DMG hash parity, and mounted-DMG verification pass.

## S79 release-verification mode — 2026-08-30

- `scripts/verify_app.sh` now distinguishes local-only evaluation from an explicit `--release` verification.
- Release verification requires Developer ID authority, a non-empty matching TeamIdentifier on the outer app and bundled selector, Gatekeeper acceptance, and stapled notarization for the app and DMG.
- Local verification remains available for development and reports its ad-hoc/notarization limitation explicitly instead of implying public-release readiness.
- S79 evidence: local installed verification passes; release verification fails closed with the actionable ad-hoc-signature message. Report: `artifacts/tauri-e2e/s79-local-installed-verification.txt`; rejection record: `artifacts/tauri-e2e/s79-release-rejection.txt`.
- Developer ID credentials and physical toolbar, capture, export, shortcut, Finder-drag, and secondary-display acceptance remain open.

## S80 current-image keyboard actions — 2026-08-30

- Editor keyboard actions now refresh when Open, Paste, Crop, or a new capture replaces the current image.
- Keyboard Copy and Save therefore use the current capture instead of a stale pre-import closure that still reports “Capture an image before…” after an image is visible.
- S80 evidence: 44 frontend tests, TypeScript/Vite build, exact arm64 package/install, strict installed-app verification, mounted-DMG verification, and one active ShotEye process pass. Reports: `artifacts/tauri-e2e/s80-final-installed-verification.txt` and `artifacts/tauri-e2e/s80-final-dmg-verification.txt`.
- Physical keyboard, toolbar, area-drag, export, shortcut, Finder-drag, secondary-display, and Developer ID/notarized acceptance remain open.

## S81 guarded Edit menu actions — 2026-08-30

- Native Edit-menu Undo, Redo, Clear, and Reset actions now share the same capture-active mutation boundary as toolbar and keyboard actions.
- Clear and Reset converge all transient annotation interaction state, including move, resize, crop, and draw drafts, so a menu command cannot leave a stale gesture active.
- S81 evidence: 44 frontend tests, TypeScript/Vite build, exact arm64 package/install, strict installed-app verification, mounted-DMG verification, and one active ShotEye process pass. Reports: `artifacts/tauri-e2e/s81-final-installed-verification.txt` and `artifacts/tauri-e2e/s81-final-dmg-verification.txt`.
- Packaged frontend-to-Rust IPC acceptance, physical keyboard/UI interaction, area-drag, export, shortcut, Finder-drag, secondary-display, and Developer ID/notarized acceptance remain open.

## S82 capture and shortcut recovery — 2026-08-30

- A valid native capture is committed to the editor before a best-effort show/focus restoration error is surfaced, so Copy and Save remain available after recovery trouble.
- Startup recovery now retries the default global shortcut after a saved custom shortcut fails; if that retry also fails, the UI explicitly reports that no global capture shortcut is active instead of displaying a misleading active key.
- S82 evidence: 44 frontend tests, 37 Rust tests, TypeScript/Vite build, exact arm64 package/install, strict installed-app verification, mounted-DMG verification, and one active ShotEye process pass. Reports: `artifacts/tauri-e2e/s82-final-installed-verification.txt` and `artifacts/tauri-e2e/s82-final-dmg-verification.txt`.
- Packaged frontend-to-Rust IPC acceptance, physical keyboard/UI, area-drag, export, shortcut, Finder-drag, secondary-display, and Developer ID/notarized acceptance remain open.

## S83 packaged runtime-contract IPC repair — 2026-08-30

- Fixed the packaged runtime-contract report call to use Tauri's camelCase JavaScript argument mapping for Rust command parameters; the previous snake_case payload was rejected before the report handler ran and left the verifier waiting for 30 seconds.
- Added a small shared frontend payload helper and regression test so the `runtime_contract_report` command contract remains explicit and covered.
- S83 evidence: 45 frontend tests, 38 Rust tests, TypeScript/Vite build, exact arm64 package/install, strict installed-app verification, mounted-DMG verification, one active ShotEye process, and packaged runtime contract PASS. Reports: `artifacts/tauri-e2e/s83-runtime-contract-final.txt`, `artifacts/tauri-e2e/s83-final-installed-verification.txt`, and `artifacts/tauri-e2e/s83-final-dmg-verification.txt`.
- The installed app and canonical DMG are local ad-hoc evaluation artifacts. Physical area drag, Copy/Save, global shortcut invocation, Finder drag, secondary-display capture, Developer ID signing, and notarization remain external acceptance gates.

## S84 native capture lifecycle hardening — 2026-08-30

- Moved blocking capture work behind Tauri's blocking worker boundary so the WebKit/UI command path is not occupied while the native selector or `screencapture` process waits.
- Made Rust the single owner of hide → capture → restore/focus. React now reports the native result without issuing a second restoration sequence.
- Restoration errors are no longer discarded: they are recorded in the capture lifecycle state, surfaced in the capture status, and included in the packaged runtime contract.
- S84 evidence: 42 frontend tests, 39 Rust tests, TypeScript/Vite build, exact arm64 package/install, strict installed-app verification, mounted-DMG verification, one active ShotEye process, and packaged runtime contract PASS. Reports: `artifacts/tauri-e2e/s84-runtime-contract.txt`, `artifacts/tauri-e2e/s84-final-installed-verification.txt`, and `artifacts/tauri-e2e/s84-final-dmg-verification.txt`.
- The local package remains ad-hoc. Physical selector drag/cancellation, Copy/Save, global shortcut invocation, secondary-display capture, Developer ID signing, Gatekeeper, and notarization remain external gates.

## S85 lifecycle evidence hardening — 2026-08-30

- Runtime traces now clear the prior per-run trace before launching the exact packaged app and record explicit native restore start, completion, and failure events.
- S85 evidence: 42 frontend tests, 39 Rust tests, TypeScript/Vite build, shell syntax and diff checks, exact arm64 package/install, packaged runtime contract PASS, installed-app verification, mounted-DMG verification, and one active ShotEye process. Reports: `artifacts/tauri-e2e/s85-runtime-contract.txt`, `artifacts/tauri-e2e/s85-final-installed-verification.txt`, and `artifacts/tauri-e2e/s85-final-dmg-verification.txt`.
- The trace proves the synthetic packaged lifecycle boundary only; delayed real selector responsiveness, physical pointer/shortcut/export flows, secondary-display capture, Developer ID signing, Gatekeeper, and notarization remain external gates.

## S86 revision-stable crop boundary — 2026-08-30

- Extracted the async crop commit guard into a small revision-stable helper used by the production crop pipeline.
- Added deterministic delayed-work regressions for Crop → Reset and Crop → annotation interleavings; stale crop results now resolve as an explicit no-op before visible state can change.
- S86 evidence: RED proof before the helper existed, 45 frontend tests, TypeScript/Vite build, 39 Rust tests, exact arm64 package/install, packaged runtime contract PASS, strict installed-app verification, and exact mounted-DMG verification. Reports: `artifacts/tauri-e2e/s86-runtime-contract.txt`, `artifacts/tauri-e2e/s86-final-installed-verification.txt`, and `artifacts/tauri-e2e/s86-final-dmg-verification.txt`.
- A component-level React harness for deferred browser image/canvas work, physical selector/shortcut/export interaction, secondary-display capture, and Developer ID/notarization remain open.

## S87 packaged React crop lifecycle evidence — 2026-08-30

- Added an explicit jsdom/React Testing Library harness for the real editor component, with Tauri/native calls mocked only at the boundary.
- The harness drives Paste → Crop pointer selection, holds browser image decoding, performs Reset or a Text annotation, and proves the delayed crop cannot replace the newer visible image, status, or annotation count.
- S87 evidence: 47 frontend tests, TypeScript/Vite build, 39 Rust tests, Rust check, exact arm64 package/install, packaged runtime contract PASS, strict installed-app verification, exact mounted-DMG verification, and canonical DMG hash parity. Reports: `artifacts/tauri-e2e/s87-runtime-contract.txt`, `artifacts/tauri-e2e/s87-final-installed-verification.txt`, and `artifacts/tauri-e2e/s87-final-dmg-verification.txt`.
- Physical selector/shortcut/export interaction, secondary-display capture, Developer ID signing, Gatekeeper, and notarization remain open.

## S88 packaged React capture lifecycle evidence — 2026-08-30

- Extended the real `App` DOM harness with native capture success coverage, a pending-operation re-entry guard, rejected-capture recovery, and native cancellation recovery.
- The harness proves the visible selecting state is published while the native capture promise is pending, a second capture request cannot overlap the first, and both cancellation shapes restore an actionable editor state.
- S88 evidence: 51 frontend tests across 14 files, TypeScript/Vite build, 39 Rust tests, Rust check, exact arm64 package/install, packaged runtime contract PASS, strict installed-app verification, exact mounted-DMG verification, and canonical DMG hash parity. Reports: `artifacts/tauri-e2e/s88-runtime-contract.txt`, `artifacts/tauri-e2e/s88-final-installed-verification.txt`, and `artifacts/tauri-e2e/s88-final-dmg-verification.txt`.
- The stable local DMG is `/Users/colbert1/shoteye/artifacts/releases/ShotEye_0.1.0_aarch64.dmg`. It is an ad-hoc evaluation artifact; physical selector drag, global shortcut invocation, Copy/Save, Finder drag, secondary-display capture, Developer ID signing, Gatekeeper, and notarization remain open.

## S107 packaged selector-cancellation harness — 2026-08-30

- Extended `scripts/verify_ui_smoke.sh` with an explicit `--capture-cancel` mode. After the non-destructive toolbar/menu gate, it checks the installed helper's non-prompting Screen Recording preflight, invokes `Capture area`, observes the exact bundled `ShotEyeSelector` process, sends Escape, waits for the selector to exit, and verifies that the ShotEye editor window is visible again.
- The default smoke mode remains non-destructive and does not invoke capture. The cancellation mode is fail-closed: it returns `Result: BLOCKED` when Accessibility, an unlocked desktop, or Screen Recording is unavailable; it returns `FAIL` only after those prerequisites passed and an expected lifecycle transition failed.
- Corrected the AppleScript process targeting to the actual packaged executable process name (`shoteye`). A bundle-identifier query was not a valid System Events process lookup and was removed after producing a reproducible `-1728` lookup error.
- S107 syntax and blocked-state evidence passed: shell syntax exit `0`; normal smoke exit `2`; opt-in cancellation smoke exit `2`; both reports record `Result: BLOCKED` with macOS `-25211` because assistive access is denied. Physical selector launch/cancel, shortcut, export, and secondary-display acceptance remain operator-gated.

## S108 selector permission mismatch hardening — 2026-08-30

- Fixed the capture dispatch path so an explicit Screen Recording denial from the bundled `ShotEyeSelector` stops before `/usr/sbin/screencapture`. This removes the fallback path that could reopen the macOS consent prompt on every capture when the parent and helper TCC identities disagree.
- Preserved fallback behavior for an inconclusive helper probe or a recoverable helper launch failure, while keeping timeout and explicit permission-denial paths fail-closed.
- Added Rust regressions for explicit probe denial, helper exit-code `3`, and the actionable no-repeat-prompt capture message. Focused capture coverage is green (18 tests) and selector dispatch coverage is green (4 tests); the full frontend suite remains green (71 tests), with TypeScript, Rust check, and Clippy clean.
- Rebuilt and installed the arm64 local-signed package. Runtime contract, strict installed-app verification, mounted-DMG verification, helper permission/display-read/geometry/compositor/selection self-tests, and one-process launch all pass. Physical Accessibility smoke remains `BLOCKED` with `-25211` and does not constitute capture acceptance.

## S109 parent/helper permission diagnostics — 2026-08-30

- Extended the non-prompting permission-status command to inspect both the Tauri parent and the bundled `ShotEyeSelector` identity on a bounded worker thread.
- The editor can now distinguish: parent access unavailable; parent/helper TCC mismatch; helper probe inconclusive; and both identities available. The mismatch message names the exact installed ShotEye entry and tells the user to quit/relaunch without opening another prompt.
- Added pure Rust coverage for all diagnostic states. Full Rust coverage is 42/42, frontend coverage 71/71, TypeScript build, `cargo check`, and Clippy are clean.
- Rebuilt/installed the arm64 local package. The new diagnostic strings are present in the installed executable; runtime contract, strict package verification, mounted-DMG verification, helper self-tests, and one-process launch pass. Accessibility smoke remains blocked by `-25211`.

## S110 status-footer recovery UI — 2026-08-30

- Replaced the fixed-height status row with an auto-growing grid track and responsive wrapping so long permission/recovery messages remain readable instead of overlapping or clipping the editor.
- Marked the status footer as a polite live region (`role="status"`, `aria-live="polite"`) so asynchronous capture and permission outcomes are announced consistently to assistive technology.
- Added a real App regression for the status-region contract. The current source still contains no duplicate traffic-light/header markup; that earlier visual symptom was not reproduced in the current tree.
- S110 evidence: focused App 20/20, full frontend 72/72 across 15 files, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, exact arm64 package/install, packaged runtime contract, strict installed-app verification, mounted-DMG verification, and canonical DMG parity. Reports: `artifacts/tauri-e2e/s110-runtime-contract.txt`, `artifacts/tauri-e2e/s110-final-installed-verification.txt`, and `artifacts/tauri-e2e/s110-final-dmg-verification.txt`.
- Physical UI smoke and opt-in capture-cancel smoke remain `BLOCKED` with macOS Accessibility error `-25211`; no toolbar-click, drag-selection, shortcut, Copy/Save, or secondary-display acceptance is claimed. Developer ID signing, Gatekeeper, notarization, and unlocked-desktop acceptance remain open.

## S111 Finder image drop import — 2026-08-30

- Added a typed Tauri file-drop path for PNG, JPEG, and TIFF files, selecting the first supported image from a mixed Finder drop and failing closed for malformed or unsupported payloads.
- Reused the existing guarded `open_image` command and canonical capture state, so dropped images receive the same dimensions, history, annotation reset, Copy, Save, and Drag behavior as dialog imports.
- Added a visible drop affordance and safe cleanup for enter, leave, and drop listener lifecycles.
- S111 evidence: focused App 21/21, image-drop helper 10/10, full frontend 83/83 across 16 files, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, exact arm64 package/install, packaged runtime contract, strict installed-app verification, mounted-DMG verification, and canonical DMG parity. Reports: `artifacts/tauri-e2e/s111-runtime-contract.txt`, `artifacts/tauri-e2e/s111-final-installed-verification.txt`, and `artifacts/tauri-e2e/s111-final-dmg-verification.txt`.
- Physical Finder drop, toolbar interaction, selector drag, shortcut, Clipboard/Save, and secondary-display acceptance remain unverified because macOS Accessibility is blocked by `-25211`. Developer ID signing, Gatekeeper, and notarization remain open.

## S112 privacy-safe Pixelate annotation — 2026-08-30

- Added a first-class Pixelate annotation to the shared source-coordinate model. It supports the same selection, move, resize, undo/redo, crop, Copy, Save, and Drag flows as the existing rectangle and Redact tools.
- The live editor renders a privacy-preserving block pattern, while the export compositor replaces each source block with one sampled color. If canvas pixel reads are unavailable, composition fails closed to an opaque black block rather than exporting unmasked pixels.
- Added renderer coverage for block replacement and the opaque fallback, plus real App coverage proving Pixelate reaches the shared annotated Copy path.
- S112 evidence: focused annotation/App coverage 32/32, full frontend 87/87 across 16 files, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, exact arm64 package/install, packaged runtime contract, strict installed-app verification, mounted-DMG verification, and canonical DMG refresh. Reports: `artifacts/tauri-e2e/s112-runtime-contract.txt`, `artifacts/tauri-e2e/s112-final-installed-verification.txt`, and `artifacts/tauri-e2e/s112-final-dmg-verification.txt`.
- Physical Pixelate interaction, selector drag, shortcut, Clipboard/Save, Finder drop, and secondary-display acceptance remain unverified because macOS Accessibility is blocked by `-25211`. Developer ID signing, Gatekeeper, and notarization remain open.

## S113 privacy-safe Blur annotation — 2026-08-30

- Added a first-class Blur annotation to the shared source-coordinate model. It supports the same selection, move, resize, undo/redo, crop, Copy, Save, and Drag flows as the existing rectangle-like privacy tools.
- The live editor overlays a clipped native-style Gaussian blur preview, while export composition applies a bounded separable box blur to the selected source region. If canvas pixel reads are unavailable, composition fails closed to an opaque black block rather than exporting unblurred pixels.
- Added renderer coverage for sharp-boundary averaging and the opaque fallback, real App coverage proving Blur reaches the shared annotated Copy path, and UI-harness inventory coverage for both privacy tools.
- S113 evidence: focused annotation/App coverage 36/36, full frontend 91/91 across 16 files, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, shell syntax, exact arm64 package/install, packaged runtime contract, strict installed-app verification, mounted-DMG verification, and canonical DMG refresh. Reports: `artifacts/tauri-e2e/s113-runtime-contract.txt`, `artifacts/tauri-e2e/s113-final-installed-verification.txt`, and `artifacts/tauri-e2e/s113-final-dmg-verification.txt`.
- The independent physical UI smoke report is `artifacts/tauri-e2e/s113-physical-ui-smoke.txt` and is correctly `BLOCKED` by macOS Accessibility error `-25211`; no physical Blur, selector, shortcut, Clipboard/Save, Finder-drop, or secondary-display acceptance is claimed. Developer ID signing, Gatekeeper, and notarization remain open.

## S114 native Tools menu discoverability — 2026-08-30

- Added a native macOS Tools menu exposing Select, Crop, Arrow, Rectangle, Text, Draw, Redact, Pixelate, and Blur.
- Routed every native Tools item through the same current React tool-selection dispatcher as the toolbar, including capture-active protection and transient-gesture cleanup, so menu actions cannot use stale render state or create a second editing path.
- Added menu-model coverage and a real App regression proving a native Tools action activates the corresponding editor tool.
- S114 evidence: focused menu/App 26/26, full frontend 92/92 across 16 files, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, shell syntax, exact arm64 package/install, packaged runtime contract, strict installed-app verification, and mounted-DMG verification. Reports: `artifacts/tauri-e2e/s114-runtime-contract.txt`, `artifacts/tauri-e2e/s114-final-installed-verification.txt`, `artifacts/tauri-e2e/s114-final-dmg-verification.txt`.
- The independent physical UI smoke report is `artifacts/tauri-e2e/s114-physical-ui-smoke.txt` and is correctly `BLOCKED` by macOS Accessibility error `-25211`; no physical menu/toolbar click, selector, shortcut, Clipboard/Save, Finder-drop, or secondary-display acceptance is claimed. Developer ID signing, Gatekeeper, notarization, and unlocked-desktop acceptance remain open.

## S115 repeat-capture keyboard shortcut — 2026-08-30

- Added `⌘⇧R`/`⌃⇧R` Repeat Last Capture mapping to the shared editor shortcut dispatcher and routed it through the existing guarded repeat-capture lifecycle.
- Added helper coverage and a real App keyboard-event regression proving the shortcut invokes `repeat_last_capture` and restores the canonical preview/status path.
- S115 evidence: focused shortcut/App 30/30, full frontend 94/94 across 16 files, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, exact arm64 package/install, packaged runtime contract, strict installed-app verification, and mounted-DMG verification. Reports: `artifacts/tauri-e2e/s115-runtime-contract.txt`, `artifacts/tauri-e2e/s115-final-installed-verification.txt`, `artifacts/tauri-e2e/s115-final-dmg-verification.txt`.
- The independent physical UI smoke report is `artifacts/tauri-e2e/s115-physical-ui-smoke.txt` and is correctly `BLOCKED` by macOS Accessibility error `-25211`; physical shortcut invocation and the remaining selector, Clipboard/Save, Finder-drop, and secondary-display acceptance remain unclaimed. Developer ID signing, Gatekeeper, notarization, and unlocked-desktop acceptance remain open.

## S116 repeat shortcut discoverability — 2026-08-30

- Added the `⌘⇧R` hint, `aria-keyshortcuts`, and an explanatory tooltip to the toolbar's Repeat Last Capture control.
- Added `CmdOrCtrl+Shift+R` to the native Capture menu item, keeping toolbar, keyboard, and menu entry points on the same guarded repeat-capture lifecycle.
- Added menu-model and real App accessibility metadata coverage. Focused menu/App coverage passed 28/28; the full frontend suite passed 95/95 across 16 files, with TypeScript/Vite build, Rust 42/42, `cargo check`, and Clippy clean.
- Rebuilt and installed the exact arm64 package. Runtime contract, strict installed-package verification, and mounted-DMG verification passed; the canonical DMG SHA-256 is `279d56c00a65720c6341988504f67be9738beb545221714ef9ac3a2afe791674`.
- Reports: `artifacts/tauri-e2e/s116-runtime-contract.txt`, `artifacts/tauri-e2e/s116-final-installed-verification.txt`, and `artifacts/tauri-e2e/s116-final-dmg-verification.txt`. Physical smoke is preserved in `artifacts/tauri-e2e/s116-physical-ui-smoke.txt` and remains `BLOCKED` by Accessibility error `-25211`; Developer ID signing, Gatekeeper, notarization, and unlocked-desktop interaction remain open.

## S117 canonical repeat shortcut contract — 2026-08-30

- Centralized the Repeat Last Capture registration value and derived the native-menu accelerator and WAI-ARIA representation from it, preventing future command-surface drift.
- Added a focused contract regression. Focused shortcut/menu/App coverage passed 33/33; the full frontend suite passed 96/96 across 16 files, with TypeScript/Vite build, Rust 42/42, `cargo check`, and Clippy clean.
- Rebuilt and installed the exact arm64 package. Runtime contract, strict installed-package verification, and mounted-DMG verification passed; the canonical DMG SHA-256 is `1921eccd1a8a2c23de136273a295635430c8d3c08f54fc2bde1a169bc6161f42`.
- Reports: `artifacts/tauri-e2e/s117-runtime-contract.txt`, `artifacts/tauri-e2e/s117-final-installed-verification.txt`, and `artifacts/tauri-e2e/s117-final-dmg-verification.txt`. Physical smoke is preserved in `artifacts/tauri-e2e/s117-physical-ui-smoke.txt` and remains `BLOCKED` by Accessibility error `-25211`; Developer ID signing, Gatekeeper, notarization, and unlocked-desktop interaction remain open.

## S118 primary toolbar shortcut discoverability — 2026-08-30

- Added visible shortcut hints, tooltips, and `aria-keyshortcuts` metadata to the primary Open, Paste, Copy, Save, Undo, Redo, and Repeat toolbar controls while preserving their existing guarded actions and accessible names.
- Centralized the primary shortcut contract and derived native-menu accelerators from the same registration values.
- Added real App toolbar coverage and shortcut-contract coverage. Focused menu/shortcut/App coverage passed 35/35; the full frontend suite passed 98/98 across 16 files, with TypeScript/Vite build, Rust 42/42, `cargo check`, and Clippy clean.
- Rebuilt and installed the exact arm64 package. Runtime contract, strict installed-package verification, and mounted-DMG verification passed; the canonical DMG SHA-256 is `b2b04a920814dac71edb1378a618d64a34bc6abcea690ea098e8429b00bc9211`.
- Reports: `artifacts/tauri-e2e/s118-runtime-contract.txt`, `artifacts/tauri-e2e/s118-final-installed-verification.txt`, and `artifacts/tauri-e2e/s118-final-dmg-verification.txt`. Physical smoke is preserved in `artifacts/tauri-e2e/s118-physical-ui-smoke.txt` and remains `BLOCKED` by Accessibility error `-25211`; Developer ID signing, Gatekeeper, notarization, and unlocked-desktop interaction remain open.

## S119 release notarization order — 2026-08-30

- Added a shared release notarization helper and changed release packaging to notarize/staple the app archive and validate the app before DMG creation, then notarize/staple the DMG before refreshing the canonical download.
- Added an order regression that uses a fake `xcrun` boundary and source-order assertions; helper syntax, release-order regression, frontend 98/98, TypeScript/Vite build, Rust 42/42, `cargo check`, Clippy, local packaging, installation, runtime, installed-bundle, and mounted-DMG verification passed.
- Release mode correctly fails closed when no `SHOT_EYE_SIGNING_IDENTITY` is configured. The local package is signed by `ShotEye Local Development`, has no TeamIdentifier, and is not a public Developer ID release.
- Reports: `artifacts/tauri-e2e/s119-release-rejection.txt`, `artifacts/tauri-e2e/s119-runtime-contract.txt`, `artifacts/tauri-e2e/s119-final-installed-verification.txt`, and `artifacts/tauri-e2e/s119-final-dmg-verification.txt`. Physical smoke remains `BLOCKED` by Accessibility error `-25211`; physical selector/export acceptance and Developer ID/Gatekeeper/notarization remain open.

## S120 area permission identity reconciliation — 2026-08-30

- Reconciled area-capture readiness with the bundled selector identity that actually reads display pixels, while retaining a fail-closed path for explicit selector denial or inconclusive checks.
- Fixed the packaged failure where the parent Tauri preflight reported unavailable even though the bundled selector had Screen Recording access. Area capture now accepts an explicit selector grant; window/full-screen capture continues to require the system capture grant.
- Added Rust regressions for the stale parent/authorized selector matrix and denial-safe effective permission handling. Focused and full frontend/Rust checks, TypeScript/Vite build, `cargo check`, Clippy, package/install, runtime, installed-bundle, mounted-DMG, shell syntax, and release-order checks passed.
- Reports: `artifacts/tauri-e2e/s120-runtime-contract.txt`, `artifacts/tauri-e2e/s120-final-installed-verification.txt`, and `artifacts/tauri-e2e/s120-final-dmg-verification.txt`. Physical UI smoke remains blocked by Accessibility error `-25211`; public Developer ID/Gatekeeper/notarization remain external gates.

## S121 selector-aware permission recovery — 2026-08-30

- Changed the user-invoked Permissions action to inspect the exact bundled `ShotEyeSelector` identity before requesting macOS consent.
- A packaged selector that is authorized, explicitly denied, or inconclusive now receives a non-prompting actionable status; the parent `CGRequestScreenCaptureAccess()` request is reserved for builds without a bundled selector.
- Added a Rust permission-action matrix regression covering authorized, denied, inconclusive, parent-authorized, and unbundled states. Full Rust/frontend checks, build, Clippy, exact arm64 package/install, runtime contract, installed-bundle verification, mounted-DMG verification, and release-mode rejection passed.
- Reports: `artifacts/tauri-e2e/s121-runtime-contract.txt`, `artifacts/tauri-e2e/s121-final-installed-verification.txt`, and `artifacts/tauri-e2e/s121-final-dmg-verification.txt`. Physical UI acceptance remains blocked by Accessibility error `-25211`; Developer ID/Gatekeeper/notarization remain external gates.

## S122 helper output-boundary evidence — 2026-08-30

- Added a permission-free bundled-selector self-test that drives the production Core Graphics compositor and ImageIO PNG writer with deterministic multi-display-like inputs.
- Extended package verification to execute that self-test against the installed app and mounted DMG, requiring a real PNG signature, `8×4` dimensions, and recording the generated output hash.
- Rebuilt the exact arm64 package and passed helper, runtime-contract, installed-bundle, mounted-DMG, shell syntax, and release-order checks. This is synthetic output-boundary evidence, not physical pointer selection or secondary-display acceptance.
- Reports: `artifacts/tauri-e2e/s122-runtime-contract.txt`, `artifacts/tauri-e2e/s122-final-installed-verification.txt`, and `artifacts/tauri-e2e/s122-final-dmg-verification.txt`. Developer ID/Gatekeeper/notarization remain external gates.
## S138 installed Save acceptance — 2026-08-30

- Drove the exact installed ShotEye toolbar through a fresh area capture and Save Capture flow.
- Saved artifact: `artifacts/tauri-e2e/s138-tauri-save-acceptance.png` — valid PNG, `1000×800`, 66,800 bytes, SHA-256 `70a5e124969fd713fbee3a23d3035183343d85a16d6d068d8962f0c4cedb736c`.
- Strict signature validation passes and exactly one canonical ShotEye process is active. Open-panel reimport was exercised; WebView status is not exposed to Accessibility, so pixel-equivalence after reopen is not claimed.
## S139 release-gate audit — 2026-08-30

- Ran the release verifier against the installed package. It failed closed with `Installed app is not signed by a Developer ID Application identity`, matching the available signing identities (`ShotEye Local Development` only).
- This confirms the release guard is active; the local DMG remains suitable for evaluation, not public distribution.
- Evidence: `artifacts/tauri-e2e/s139-release-gate-output.txt`.
## S140 final local package verification — 2026-08-30

- Reverified the installed arm64 bundle and canonical DMG with the saved PNG artifact. Bundle identity, helper resource, permission probe, geometry, mixed-DPI, crop-transform, selection-event, display-read, and output-boundary checks passed.
- Evidence: `artifacts/tauri-e2e/s140-final-installed-verification.txt`. This remains local-only verification; public signing and notarization are not asserted.
## S141 acceptance-gate inventory — 2026-08-30

- Current host exposes one display (`2940×1912` pixels); secondary-display capture is not inferable from the one-display run.
- Occupied-shortcut acceptance was attempted but not claimed because Accessibility exposure was inconsistent after package verification. Evidence: `artifacts/tauri-e2e/s141-hardware-and-shortcut-gates.txt`.

## S142 stable Accessibility shortcut-conflict testing — 2026-08-30

- Added a compiled macOS AX driver with bounded hierarchy discovery, direct button activation, frontmost/focus recovery, and a Core Graphics test-key event path.
- Updated packaged UI smoke to prefer the direct AX driver and retain the native-menu/System Events fallback, reporting the selected surface explicitly.
- Added a reversible shortcut fixture and an exclusivity probe. On this host, macOS permits duplicate Carbon reservations for the test chord, so conflict acceptance correctly returns `BLOCKED` rather than claiming a ShotEye conflict.
- Evidence: `artifacts/tauri-e2e/s142-direct-ax-smoke.txt`, `artifacts/tauri-e2e/shortcut-conflict-fixture.txt`, and `artifacts/tauri-e2e/shortcut-conflict-acceptance.txt`.
- Remaining gate: use a genuinely exclusive registration boundary or permission-enabled alternate harness before claiming physical shortcut-conflict acceptance; no unrelated macOS settings were changed.

## S143 shortcut transaction hardening — 2026-08-30

- Extracted shortcut registration/replacement into a testable transaction boundary without changing the Tauri command surface.
- Added Rust coverage proving a rejected replacement preserves the last working shortcut, an old-binding removal failure rolls back the new binding, and an accepted replacement commits atomically.
- Evidence: focused `cargo test shortcut_registration` passed 4/4; full packaged conflict remains blocked by the S142 non-exclusive Carbon fixture boundary.

## S146 bounded Accessibility cancellation acceptance — 2026-09-02

- Added bounded execution around all packaged AppleScript calls so Accessibility automation cannot hang without an evidence result.
- Fresh installed-package Capture Area cancellation passed through direct AX, observed the selector, restored the editor, and left one canonical ShotEye process.
- Evidence: `artifacts/tauri-e2e/s146-capture-cancel-bounded.txt`. Shortcut conflict remains blocked only because the host permits duplicate Carbon registrations.

## S147 physical primary-display capture acceptance — 2026-09-02

- Drove the installed Capture Area toolbar control through the bundled selector and a real macOS HID desktop drag, then used ShotEye's Copy control to export the result.
- The copied image is a valid `1000×800` PNG with an upright visual orientation.
- Evidence: `artifacts/tauri-e2e/s147-physical-area-copy.txt` and `artifacts/tauri-e2e/s147-physical-area-copy.png`.

## S148 repeatable physical primary-display capture acceptance — 2026-09-02

- Added a bounded installed-app acceptance script for direct toolbar Capture Area → bundled selector → real HID drag → editor restoration → Copy Capture clipboard export.
- The script validates strict bundle signing, one exact app process, selector cleanup, PNG signature, dimensions, and output hash. The fresh copied image is visually upright at `1000×800`.
- Evidence: `scripts/test_physical_area_capture.sh`, `artifacts/tauri-e2e/s148-physical-area-copy.txt`, `artifacts/tauri-e2e/s148-physical-area-copy.png`, `artifacts/tauri-e2e/s148-capture-cancel-serial.txt`, and `artifacts/tauri-e2e/s148-package-verification.txt`.
- The harness now refuses report/artifact paths outside `artifacts/tauri-e2e`; fresh serial S149 and S150 runs also passed with separate upright `1000×800` PNGs and one canonical process.
- The shortcut-conflict fixture remains explicitly blocked: this host allows duplicate Carbon registrations, so it cannot prove an external occupied chord. Evidence: `artifacts/tauri-e2e/shortcut-conflict-acceptance.txt`.
- S151 source audit confirms ShotEye's Tauri shortcut dependency also calls Carbon `RegisterEventHotKey`, so replacing the fixture with the product dependency cannot create an exclusive test owner. Evidence: `artifacts/tauri-e2e/s151-shortcut-conflict-boundary.txt`.

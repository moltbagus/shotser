# ShotEye Specification v1.01

## Architecture

- Tauri hosts the React editor in macOS WebKit and owns the product-facing window.
- Rust owns capture state, IPC commands, permission preflight, clipboard, save, and lifecycle boundaries.
- A bundled Swift/AppKit helper owns the area-selection surface and multi-display pixel composition; `screencapture` remains a fallback adapter.
- Rust owns a small macOS Cocoa/AppKit drag bridge for Finder export; the React editor only requests the command and reports its result.
- The root build and launch scripts target only the Tauri bundle; the historical Swift prototype is outside the supported product path.
- The native process executable is named `shoteye`; packaged updates must not leave a stale framework-template executable in `Contents/MacOS`.
- The product menu is installed through Tauri's native menu API and delegates commands to the current React action refs; it is an alternate command surface, not a second capture/export implementation. Its Tools group exposes Select, Crop, Arrow, Rectangle, Text, Draw, Redact, Pixelate, and Blur through the shared tool-selection dispatcher.
- The root build/run workflow installs the freshly built package at `/Applications/ShotEye.app` before launch or verification; the prior exact bundle is moved to a recoverable temporary backup so TCC and Launch Services observe one canonical test identity.
- Supported launch and verification use `open -a` with the exact installed `/Applications/ShotEye.app` path. They must not use `open -n` or launch an unqualified build-tree bundle, because a second process can create duplicate windows and a different macOS permission identity.
- `scripts/package_app.sh` must archive a stale unqualified `target/release/bundle/macos/ShotEye.app` outside the build tree before packaging, and must fail closed rather than moving it if its executable is running.

## S121 evidence contract

- `request_screen_capture_permission` must inspect the exact bundled selector when it is present before invoking any macOS consent API.
- Authorized selector, explicit selector denial, and inconclusive selector checks must return non-prompting actionable statuses; only a build without a bundled selector may request the parent process's initial consent.
- The Rust permission-action matrix must cover selector-authorized, selector-denied, selector-inconclusive, parent-authorized, and unbundled states.
- S121 local evidence is recorded in `artifacts/tauri-e2e/s121-runtime-contract.txt`, `artifacts/tauri-e2e/s121-final-installed-verification.txt`, and `artifacts/tauri-e2e/s121-final-dmg-verification.txt`. These artifacts do not substitute for Accessibility-enabled physical interaction or public Apple release gates.

## S122 evidence contract

- `ShotEyeSelector --self-test-capture-output <path>` must exercise the production compositor and ImageIO PNG writer without opening a selector or requesting permission.
- The helper self-test must validate deterministic seam/orientation colors, nontransparent output, and written PNG dimensions of `8×4`.
- `scripts/verify_app.sh` must run and validate the output self-test for both the exact installed bundle and the mounted canonical DMG, recording its SHA-256 and dimensions in reports.
- S122 evidence is synthetic output-boundary evidence only; it does not claim physical pointer selection, secondary-display pixels, or public Apple release readiness.

## S123 native-operation lifecycle contract

- Every native operation must call the shared begin/finish lifecycle and expose a phase to the React editor. The finish path must run for success, cancellation, rejection, and thrown IPC/native errors.
- Copy, Save, Drag, capture modes, imports, Repeat, permission actions, settings, and shortcut recording must not overlap an active native operation. The UI must expose the phase through a visible polite status element rather than relying on a ref-only guard.
- The Save file dialog is a deliberate exception for editor mutation: while the dialog is open, annotation tools remain usable, and export preparation begins only after a destination is selected so the latest revision is rendered.
- Focused component coverage must hold Copy and Drag on deferred native completion, assert competing controls are disabled, assert the operation phase is released afterward, and prove annotation controls remain enabled during Save-dialog display.
- S123 evidence is recorded in `artifacts/tauri-e2e/s123-runtime-contract.txt`, `artifacts/tauri-e2e/s123-final-installed-verification.txt`, and `artifacts/tauri-e2e/s123-final-dmg-verification.txt`. These artifacts do not substitute for physical Accessibility-enabled desktop acceptance or public Apple release gates.

## S124 shortcut registration contract

- The global capture shortcut must expose a visible state of Active, Registering, Conflict, or Not active, plus a reset-to-default action. The control must preserve its accessible name and display the shortcut in familiar macOS notation.
- Explicit shortcut registration must be single-flight. While it is pending, capture/export actions and shortcut recording must not start; a global capture event must report that registration is still in progress rather than launching a selector.
- A rejected replacement must leave the previously active shortcut and persisted preference unchanged. A successful replacement updates both only after the native command accepts it; startup recovery may clear a rejected saved value and retry the known default.
- Native error messages containing registration syntax must be formatted for users without losing the actionable conflict context.
- Focused App coverage must defer registration, assert action gating, resolve a conflict, and verify old-shortcut preservation. S124 evidence is recorded in `artifacts/tauri-e2e/s124-runtime-contract.txt`, `artifacts/tauri-e2e/s124-final-installed-verification.txt`, and `artifacts/tauri-e2e/s124-final-dmg-verification.txt`.
- Local packaging probes the installed `ShotEye Local Development` identity with a bounded non-interactive `codesign` check. When usable, it signs the bundled selector first and re-signs the outer app so both executable layers share one evaluation identity; local ad-hoc fallback remains explicit and is never release evidence.
- The bundled selector must reject any requested logical rectangle not fully covered by the union of connected display frames before it reads pixels; a display gap is not a successful transparent capture.
- Native capture children must be owned, polled, killed, and reaped after a bounded five-minute deadline; timeout must not fall through to another interactive selector. If child polling itself errors, the child must still be killed and reaped before the error is returned.
- The helper's non-prompting permission probe must use the same owned child lifecycle with a two-second deadline; timeout is inconclusive and falls back to the system selector.
- Open and Paste are canonical-image writers and must share the same exclusive native-operation lane as capture, Copy, Save, and Drag. Crop remains serialized for decode/state ordering, but must defer Rust persistence to the guarded Copy, Save, or Drag export boundary; a blocked action must not mutate Rust-owned state or start native work.
- The bundled selector must expose a noninteractive display-read self-test that performs Screen Recording preflight and reads the main display without showing a selection overlay or requesting consent; this is evidence of helper pixel access, not area-drag acceptance.
- The display-read self-test returns `3` only for a failed Screen Recording preflight and returns ordinary nonzero `1` for a failed display read or invalid image shape; installed and DMG reports record both actual exit statuses.
- Background Drag prewarming may render a revision-scoped data URL in the WebView, but it must not mutate Rust-owned canonical image state until a guarded user export begins.
- Core Graphics captures display pixels at the native boundary; Vision/OCR remains outside the current Tauri slice.
- `scripts/verify_app.sh` defaults to local-only package verification. Its `--release` (or `--require-developer-id`) mode must fail closed unless the exact app and bundled selector have Developer ID authority, matching non-empty TeamIdentifier values, Gatekeeper acceptance, and valid stapled notarization; mounted-DMG verification applies the same policy to the payload and exact DMG.

## Interaction contract

1. Launching ShotEye activates the application and brings `ShotEye Editor` forward.
2. The editor window must be key and must not ignore mouse events.
3. Pin must toggle native always-on-top through the Tauri window API, update its active state only after success, and leave the prior state unchanged after an IPC or ACL failure.
4. Every toolbar control has an action or a visible status response.
5. Native Edit-menu Undo, Redo, Clear, Reset, and Delete-equivalent mutations must use the same capture-active dispatcher as toolbar and keyboard mutations; Clear and Reset must clear all transient annotation drafts before returning to an actionable editor state.
6. When hidden capture returns both a valid result and a window-restoration error, the frontend must commit the valid image before publishing the restoration failure; Copy and Save must remain available.
5. A capture overlay must be disabled and closed before the editor is shown.
6. Duplicate launches must not create competing instances; while a native capture is active, a duplicate launch must not reveal or focus the intentionally hidden editor.
7. macOS native titlebar controls are the only close, minimize, and zoom controls; the WebView must not render an imitation titlebar.
8. The editor handles `⌘Z`/`⌘⇧Z`, `⌘O`, `⌘V`, `⌘C`, `⌘S`, and `⌘⇧R` using existing actions, while leaving text-entry fields and shortcut recording untouched. `⌘⇧R` invokes Repeat Last Capture through the same guarded capture lifecycle as the toolbar.
9. When a capture exists, the Drag control starts one native file drag from a fresh AppKit mouse-down event at the current macOS pointer location; without a capture it reports the missing prerequisite without changing editor state.
10. A global capture shortcut pressed before the WebView listener is installed is queued and delivered once after readiness; while the shortcut recorder is active, native capture requests are ignored.
11. Changing tools or cancelling a pointer gesture clears every transient crop, annotation, move, and resize draft.
14. The native area selector must clear an undersized or cancelled drag before accepting the next gesture; its preview and capture handoff must use the same normalized rectangle state.
12. The macOS File, Capture, Edit, and Help menus expose the same user workflow as the toolbar and route through the same exclusive-operation and canonical-image boundaries.
13. The native selector's helper path is used only after a positive non-prompting permission probe; an inconclusive probe must use the system selector fallback.
15. Shared toolbar buttons provide at least a 40px interaction target and a visible `:focus-visible` indicator for keyboard and assistive navigation.
16. Product toolbar icons must use stable bundled vector shapes rather than platform-dependent Unicode glyphs; each icon must remain paired with a visible label or accessible name.
17. Clipboard import and Copy must execute their AppleScript helper through a bounded owned-child lifecycle; timeout must kill/reap the helper, clean private staging, and return an actionable status.
18. Save must resolve the user-selected destination before preparing the rendered export, so edits made while the dialog is open cannot be omitted from the saved revision.
19. The supported repository launch path contains no `.app` bundle directly under root `dist/`; stale products must be archived outside that directory, and package/verification scripts must reject a duplicate there.
20. When ShotEye regains focus after leaving the app, it performs a non-prompting Screen Recording status refresh. It refreshes on focus, not blur; it never requests consent from this background check; and a late result cannot replace a newer user-owned status.

## Verification contract

- Release build succeeds.
- Fresh extracted app passes `codesign --verify --deep --strict`.
- `NSRunningApplication` reports ShotEye active after launch.
- Exactly one ShotEye process remains after a normal launch.
- The root `script/build_and_run.sh` must launch and verify the same `/Applications/ShotEye.app` bundle that the operator authorizes in macOS Privacy & Security; it must not launch the build-tree copy directly.
- The running ShotEye process command path ends in `ShotEye.app/Contents/MacOS/shoteye`.
- Local packages may be ad-hoc signed for evaluation; public packages must pass the guarded Developer ID/notarization release gate.
- The architecture-specific package validates the app and bundled selector Mach-O architecture before it is reported as distributable for local use.
- A fresh extracted ZIP must report the process active within four seconds of launch.
- The checked-in install verifier must validate the exact bundle identity, architecture, helper resource, strict signature, stale executable absence, built/installed binary parity, DMG presence, helper non-prompting preflight, and optional PNG signature/dimensions without treating those checks as physical pointer acceptance. Its `--dmg <path>` mode must mount that exact image read-only and apply the same checks to the embedded app.
- Copy, Save, and Drag are mutually exclusive user-triggered export actions. The editor must keep the guard through async preparation and native export/drag startup, report a busy status for a competing request, and release the guard on every success, cancellation, and failure path.
- Capture joins the same native-operation lane as Copy, Save, and Drag. A capture request received while any export is pending must not hide the window or invoke a second native adapter; it must return an actionable busy status and leave the current operation unchanged.
- Screen Recording permission request and settings actions share one async guard across toolbar and native-menu entry points. While either action is pending, both permission controls are disabled; a repeated request reports that the existing request is still in progress instead of invoking macOS again.

## Packaged editor verification contract

- The production bundle must compile its React assets and embed them for `tauri://localhost`.
- Every visible toolbar control must have a direct local action or a dedicated product command; tool selection must not use a diagnostic IPC acknowledgement.
- The native menu model has unique item IDs and includes Open, Paste, Copy, Save, area/window/fullscreen/repeat capture, Undo/Redo, Clear/Reset, permission recovery, and every supported editor tool.
- The installed-package verifier runs the bundled selector's deterministic geometry, mixed-DPI compositor, and crop-transform self-tests in addition to permission, identity, architecture, parity, signature, and artifact checks.
- Rust capture tests must exercise the transaction boundary through an injectable runner: valid output commits bytes and mode, cancellation/invalid output/timeout preserve the last valid capture, private output is cleaned, and helper dispatch covers fallback and no-fallback rules without requiring pointer automation.
- The frontend capture lifecycle must hide the editor before the native action, always attempt restoration and focus, and expose action and restore failures separately so restore failure keeps its established status precedence.
- The hidden-window lifecycle helper must have focused coverage for success, hide failure, native action failure, show failure, and focus failure without requiring macOS Accessibility automation.
- The bundled selector must normalize forward and reverse drag endpoints through one helper, reject either dimension below two logical points, and expose a deterministic self-test for those boundaries.
- The installed-package verifier also runs the helper's noninteractive display-read self-test for both the installed app and the exact mounted DMG payload.
- The installed-package verifier must run the selector interaction self-test for both the installed app and the exact mounted DMG payload.
- A structurally valid noninteractive system capture is boundary evidence only; if the current execution environment returns an all-black desktop artifact, it must not be used to claim visible-pixel or pointer-selection acceptance.
- The installed-package verifier must derive and validate the exact architecture/version DMG filename; it must not choose the first matching historical artifact.
- The status text must report the user-visible result of the selected action without exposing framework names or backend platform labels.
- Native capture, permission, export, and lifecycle failures must remain actionable and must not be overwritten by an unrelated delayed status response.
- Permission action success and failure messages must commit only while the action's captured status epoch is current; a later user action owns the status line when it starts.
- Capture, Open, Paste, Crop, Copy, Save, and Drag terminal statuses must commit only while their captured status epoch is current; a later user action owns the status line when it starts.

## Packaged runtime-contract IPC

- The test-only packaged runtime contract is enabled only when `SHOT_EYE_RUNTIME_CONTRACT=1` is present in the exact installed app process.
- The frontend report payload must use Tauri's default camelCase JavaScript mapping (`actionSucceeded`, `restorationSucceeded`, `previewWidth`, and `previewHeight`) for the Rust command's snake_case parameters.
- A report is valid only when the frontend readiness command has completed, capture IPC returns a valid PNG preview, preview dimensions match the Rust canonical store, window restoration succeeds, and capture activity is released.
- The checked-in runtime verifier must fail if the exact packaged app does not write a `Result: PASS` report within its bounded wait; missing reports are command-boundary failures, not acceptable diagnostic silence.

## Native capture lifecycle hardening

- `capture_area`, `capture_window`, `capture_fullscreen`, and `repeat_last_capture` are async Tauri commands whose blocking native work runs through `spawn_blocking`; the WebKit command/event path must remain available while a selector is active.
- Rust owns the complete macOS capture transaction: set the capture activity guard, hide the editor, run the native adapter, restore activation policy/window visibility/focus, and release the activity guard before the command resolves.
- React must not issue a second `show()` or `setFocus()` sequence after the native command returns. It may publish the returned capture result and status only.
- Native restoration is observable through lifecycle state. Any activation-policy, unminimize, show, or focus failure must remain actionable in the capture status and make the runtime contract fail.

## Runtime evidence trace

- Each invocation of `scripts/verify_runtime_contract.sh` must clear the requested report and its derived `.trace` artifact before launching the exact installed app, so a passing run cannot inherit stale lifecycle events.
- When runtime tracing is enabled, the native transaction records restore start, restore completion, and restore failure events in addition to capture start/hidden/end and report-entry events.
- Trace evidence is diagnostic boundary evidence; it does not replace a physical selector drag, real screen pixels, shortcut invocation, Copy/Save, or public signing acceptance.

## Release packaging contract

- `scripts/package_app.sh --release` must require the complete identity string reported by `security find-identity` and reject local/self-signed certificates before starting a build.
- Release packaging must require one complete Apple notarization credential set, invoke Tauri with the requested Developer ID signer, and validate strict code signing, `spctl`, and `xcrun stapler validate` before reporting success.
- Release packaging must validate Developer ID authority and a non-empty matching `TeamIdentifier` on both the outer app and the bundled `ShotEyeSelector` executable before Gatekeeper or notarization checks run.
- Packaging must create the DMG without an unbounded Finder cosmetic automation step; release validation must staple and validate the exact DMG submitted for notarization.
- The local `scripts/package_app.sh` path remains available for ad-hoc development packages and must not be described as a notarized release.
- The canonical installer must strict-verify the source bundle before stopping the installed process or moving the existing `/Applications/ShotEye.app` bundle.
- Verification output must label local-only evidence separately from release-ready evidence. A passing ad-hoc strict-signature check is valid development evidence but is not evidence of Developer ID distribution readiness.

## Native capture contract

- Capture area invokes macOS `screencapture` interactively and treats its temp PNG as adapter output only.
- Cancellation is a normal outcome and must return the editor to an actionable state.
- The editor window hides before interactive area selection and is shown and focused again after completion, cancellation, permission failure, or IPC failure.
- A successful capture validates PNG bytes and dimensions, stores the latest image in Rust-owned state, and previews that image in the WebKit editor.
- Copy and Save read from Rust-owned capture state; temp files are allowed only as implementation details at native OS boundaries.
- Clipboard staging files must be created in private per-operation directories, never at predictable shared `/tmp` paths, and must be cleaned after the native operation or by an RAII fallback.
- Screen Recording permission is required; the adapter must preflight access before invoking `screencapture`, so unavailable access produces an in-app status rather than repeatedly triggering the macOS consent sheet.
- Permission recovery copy must name macOS's `Screen & System Audio Recording` category and explain that ShotEye captures screen pixels only and does not record system audio; the app must not imply that audio capture is requested.
- The Permissions control is the only UI action allowed to request macOS screen-capture consent; Capture area, Full screen, and Repeat must only preflight and never surprise the user with a consent sheet.
- Permission consent and settings entry points must be serialized through one frontend guard, must release it on success and failure, and must not publish stale terminal status after a newer user action begins.
- ShotEye performs the same non-prompting Screen Recording preflight on startup and reports the result in the editor status area; startup diagnostics must never request consent or block the editor.
- The frontend capability must explicitly permit `core:window:allow-hide`, `core:window:allow-show`, and `core:window:allow-set-focus`; lifecycle code is incomplete without the packaged ACL.
- Public-beta signing must use an Apple Developer `Developer ID Application` identity and notarization. Do not substitute a locally self-signed certificate: on this build it passed strict code-signature validation but left the Tauri WebKit editor blank at launch.
- Area capture must invoke `screencapture -i -J selection` without `-m` or `-D…` flags, so macOS presents one selectable desktop coordinate space across connected displays. Verification requires one physical capture on a secondary display; a single-display Mac can only prove the command contract.
- Packaged area capture must prefer `Contents/Resources/native/ShotEyeSelector`, which returns a PNG or an explicit cancellation/error exit code. If that helper is absent, Rust may use the existing `screencapture` fallback. A helper cancellation must not trigger a second interactive selector.
- The bundled selector must accept `--check-permission` and perform only the non-prompting Core Graphics preflight, returning success when its own executable can read the display and the reserved helper permission-failure code otherwise. Rust must run this probe before creating a visible helper overlay; a reserved permission failure skips the helper and uses the system selector fallback, while any helper launch failure also falls back to the system selector.
- The bundled selector's permission-free self-test must dispatch synthetic AppKit mouse and Escape events through the real `SelectionView` handlers, verify forward/reverse callback geometry and cancellation cleanup, and confirm key/responder readiness without showing an overlay or reading display pixels.
- The default global area-capture shortcut is `CommandOrControl+Shift+Y`. A recorded replacement must contain a modifier and must register successfully before the prior shortcut is removed; a registration conflict or parser error leaves the currently active shortcut unchanged. The persisted UI setting must be re-applied after startup without losing early-launch shortcut handling.
- Startup recovery after a rejected persisted shortcut must explicitly retry the default shortcut. The UI may claim the default is active only after that retry succeeds; otherwise it must report that no global capture shortcut is active and allow a replacement to be recorded.
- Default shortcut registration during Tauri startup is best-effort. If `CommandOrControl+Shift+Y` is unavailable, the editor must still launch, retain an unregistered current value, and let the frontend retry or record a replacement; the UI must surface the native registration failure rather than claim the shortcut is active.
- A persisted custom shortcut is advisory. During startup, if native registration rejects the saved value, the frontend must clear that stale preference, display the known active default `CommandOrControl+Shift+Y`, and leave the default registration active. During an explicit user replacement, a rejection must leave both the active shortcut and the displayed saved preference unchanged.
- Window capture invokes `screencapture -i -J window` through the same permission preflight and canonical capture pipeline; it must hide and restore the editor, distinguish Escape cancellation, and become the repeat mode after a successful window capture.
- The product UI renders registered shortcuts in familiar macOS notation, while Rust retains platform-neutral registration syntax at the command boundary.
- The editor keydown listener must refresh whenever the current capture changes, so keyboard Copy and Save cannot retain a no-image closure after Open, Paste, Crop, or capture completion.
- The permission toolbar must expose separate `Permissions` and `Open Screen Recording settings` actions. The latter only navigates to the scoped macOS preference pane; it does not request or imply consent.
- The macOS bundle must include `NSScreenCaptureUsageDescription`, and `LSMinimumSystemVersion` must not be lower than the minimum supported by the bundled native selector.
- The bundled selector panel must be key-capable, cancel on Escape or deactivation, and be ordered out before `CGDisplayCreateImage` runs.
- The bundled selector must return exit code `4` for a selection crossing a display gap; Rust must surface this as an actionable rejection without retaining a new capture.
- A native capture timeout must preserve the last valid capture, return an actionable timeout status, and release the frontend lifecycle guard through the existing restoration path.
- Native display composition must use a documented coordinate transform that preserves top-to-bottom monitor order for negative, positive, and vertically arranged display origins.
- Native display composition must use an explicit RGBA output context, nearest-neighbor interpolation, and the maximum backing scale of participating displays. Source crops and destination edges must use floor-min/ceil-max backing-pixel bounds; its permission-free self-test must verify dimensions, seam ownership, vertical orientation, opaque coverage, and pixel classes across the complete output.
- The native crop transform must be tested against top-row-first synthetic image data for selections near both the top and bottom of a display; the settings-opening command must have a bounded child lifetime and an actionable timeout result.
- A failed or cancelled native capture must preserve the last valid Rust-owned capture so the visible preview and Copy/Save state cannot diverge.
- A cross-display selection must fail if any display intersecting the selection cannot be captured; a partial transparent composite is not a successful capture.
- Helper exit code `2` means cancellation; helper exit code `3` means helper-side Screen Recording preflight failure and may use the system selector fallback; other nonzero exits are failures and must not be relabeled as cancellation.
- Drag-out stages the latest Rust-owned canonical PNG into a private `0700` directory, schedules AppKit work on the main thread, and supplies Finder an `NSURL`-backed `NSDraggingItem`. The bridge synthesizes a fresh mouse-down event after the IPC hop, supplies a visible PNG drag image, and cleans the staged location when AppKit reports the drag session ended. A missing window or failed drag session returns an actionable error and preserves the capture.

## Annotation and export contract

- Rectangle, Arrow, Text, Draw, Redact, Pixelate, and Blur annotations are represented in source-image coordinates, so their placement is independent of editor zoom.
- Preview rendering uses an SVG overlay and must not mutate the original capture.
- Copy and Save rasterize the current overlay into a PNG at the export boundary, then replace the Rust-owned canonical export record before calling the native clipboard/save adapter.
- Save accepts only `.png`, `.jpg/.jpeg`, or `.tif/.tiff`; PNG preserves the canonical bytes, while JPEG/TIFF are encoded at the Rust boundary and must retain the source dimensions. Copy remains PNG-only.
- Save must finish encoding before touching the selected destination, write the complete payload to a unique same-directory staging file, sync it, and atomically rename it into place; failures must clean staging state and preserve the previous destination file.
- Degenerate drags and empty text are ignored; Escape cancels an in-progress annotation; Undo and Clear do not alter the original capture.
- Undo removes the newest annotation and enables Redo; Redo restores the newest undone annotation. Adding a new annotation or clearing annotations invalidates the redo branch.
- Select hit-tests annotations in source-image coordinates, chooses the topmost match, and Delete/Backspace removes it through the shared history model.
- Select-drag moves the chosen annotation in source-image coordinates and commits one Undo history entry on pointer release; a click without movement does not change history.
- Selected rectangles expose four corner handles (`nw`, `ne`, `se`, `sw`) and selected arrows expose `start` and `end` handles. Handle drags derive from the pointer-down annotation snapshot, preview in source-image coordinates, and commit one Undo history entry only when the final geometry is meaningful. Escape, tool changes, and pointer cancellation discard an in-progress resize.
- Crop must normalize its two pointer endpoints into non-negative source-image bounds before rasterization. A successful crop flattens existing annotations into the cropped PNG; Reset restores the original imported or captured image and clears edits.
- Async crop rasterization must resolve through a revision-stable boundary: if Reset, import, or an annotation-history mutation advances the image-edit revision while browser image/canvas work is pending, the result must be discarded as a no-op rather than replacing the current editor state.
- Drag-out uses the same canonical annotated image prepared for Copy/Save. It is PNG-only, uses the product filename `ShotEye Capture.png`, and must not clear or mutate annotations.
- Async Copy, Save, and Drag preparation must read the latest capture, dimensions, and annotations through synchronous refs and validate a capture/annotation revision after preparation. A changed revision must retry from the latest state; after bounded retries the action must fail visibly without advertising stale export data.
- The frontend test suite must mount the editor through a DOM harness and exercise delayed crop work through the real Paste → Crop pointer path. Reset and annotation interleavings must leave the newer image, status, and annotation state intact when the deferred crop resolves.
- The frontend DOM harness must also drive the real Capture area entry point through success, pending re-entry, rejected capture, and native cancellation paths; each terminal path must leave the editor actionable and must never start overlapping native captures.

## Image import contract

- Open accepts PNG, JPEG, and TIFF files through the native dialog; clipboard import accepts native PNG first and TIFF as a fallback.
- Every accepted import is decoded and re-encoded as an RGBA PNG before it enters Rust-owned capture state. Unsupported or corrupt bytes must leave the current editor image unchanged.
- A successful image import clears only the prior annotation draft/history and resets zoom; it must provide the dimensions and an actionable status message.

## S89 evidence contract

- The App-level DOM harness must drive an annotated image through Copy, Save, and Drag. It must hold browser image decoding when needed, observe canvas annotation rasterization, wait for the Save destination before preparation, and verify Drag reaches the native adapter through the same prepared revision.
- Local packaged evidence for S89 is recorded in `artifacts/tauri-e2e/s89-runtime-contract.txt`, `artifacts/tauri-e2e/s89-final-installed-verification.txt`, and `artifacts/tauri-e2e/s89-final-dmg-verification.txt`; these checks do not substitute for physical Clipboard, Save-dialog, Finder-drag, or Accessibility-enabled acceptance.

## S90 evidence contract

- Local packaging must use `ShotEye Local Development` only after the bounded private-key probe succeeds; a probe timeout or rejection must not block local evaluation on a Mac without that identity.
- When the local identity is used, the app, main executable, and bundled selector must report the same `Authority=ShotEye Local Development`, and `codesign --verify --deep --strict` must pass for the installed package.
- S90 evidence is recorded in `artifacts/tauri-e2e/s90-runtime-contract.txt`, `artifacts/tauri-e2e/s90-final-installed-verification.txt`, `artifacts/tauri-e2e/s90-final-dmg-verification.txt`, and the byte-identical canonical DMG under `artifacts/releases/`.
- Local identity evidence does not satisfy Developer ID, Team ID, Gatekeeper, notarization, or physical Accessibility-enabled capture/export acceptance.

## S91 evidence contract

- The real React `App` capture harness must exercise the accessible Window, Full screen, and Repeat last capture controls through the shared lifecycle and assert the requested native command, valid preview, restored control state, and terminal status.
- Focused S91 evidence is the 13-test `App.crop.test.tsx` harness; the complete frontend suite must be rerun before the sprint is recorded complete.
- These component tests prove command routing and UI recovery only; they do not substitute for physical selector drag, shortcut, Clipboard/Save, Finder drag, secondary-display, or public Apple release acceptance.

## S92 evidence contract

- Runtime-contract startup must await completion of the asynchronous capture-listener registration before signaling frontend readiness; this prevents a queued global shortcut event from being emitted into an unlistened WebView.
- Packaging must atomically refresh the architecture-specific canonical DMG under `artifacts/releases/` from the just-created DMG and verify byte parity before reporting success.
- Installed/build DMG verification must compare the requested or built DMG to that canonical artifact and reject mismatches before mounting or accepting the payload.
- S92 evidence is recorded in `artifacts/tauri-e2e/s92-runtime-contract.txt`, `artifacts/tauri-e2e/s92-final-installed-verification.txt`, `artifacts/tauri-e2e/s92-final-dmg-verification.txt`, and the canonical DMG; the negative parity probe is recorded in the execution report/task log.

## Session capture history contract

- A successful capture or accepted image import creates one immutable `CaptureHistoryEntry` containing a stable id, data URL, pixel dimensions, and creation timestamp.
- The frontend retains at most eight entries and at most 128 MiB of encoded data, prepends the newest result, removes a repeated id before insertion, and never mutates the previous history array.
- Cancellation, permission failure, malformed image output, and failed imports do not change capture history.
- The Recent captures UI must expose keyboard-accessible restore buttons with dimensions and must identify the currently displayed entry without relying on thumbnail pixels alone.
- Restoring history is serialized through the existing native-operation lane, replaces the canonical editor source image, clears annotation/crop transient state, resets zoom to 100%, and leaves the editor actionable after a busy or failure path.
- History is session-scoped and intentionally cleared on relaunch; durable history requires a separate privacy/storage decision.
- The Recent captures surface must expose an accessible `Clear history` action. It clears every in-memory history entry, preserves the current canonical editor image, reports a user-visible status, and is disabled while capture is active.

## S93 evidence contract

- The App-level DOM harness must drive Paste/import, a second Capture area result, and restore of the earlier entry, asserting the restored source image, dimensions, and status.
- The capture-history helper tests must cover immutable prepend, bounded retention, repeated-id replacement, and non-positive limits.
- S93 packaged evidence is recorded in `artifacts/tauri-e2e/s93-runtime-contract.txt`, `artifacts/tauri-e2e/s93-final-installed-verification.txt`, `artifacts/tauri-e2e/s93-final-dmg-verification.txt`, and the canonical DMG under `artifacts/releases/`. These checks do not substitute for physical selector, export, Accessibility, or public Apple release acceptance.

## S95 evidence contract

- Capture history must enforce both `MAX_CAPTURE_HISTORY = 8` and `MAX_CAPTURE_HISTORY_DATA_BYTES = 128 MiB`; insertion tests must prove older entries are evicted when the encoded data budget is reached.
- The exact arm64 package must be rebuilt after the history-budget change, installed at `/Applications/ShotEye.app`, and verified through runtime contract, strict installed-bundle, mounted-DMG, and canonical DMG parity checks.
- S95 evidence is recorded in `artifacts/tauri-e2e/s95-runtime-contract.txt`, `artifacts/tauri-e2e/s95-final-installed-verification.txt`, `artifacts/tauri-e2e/s95-final-dmg-verification.txt`, and `artifacts/releases/ShotEye_0.1.0_aarch64.dmg`.
- Missing local `rustfmt` and `clippy` components are an environment limitation and must not be represented as passing lint checks.

## S96 evidence contract

- Native lint verification must run with the Rust `clippy` component installed and report zero warnings for `cargo clippy --lib --all-targets`.
- `cargo fmt --all -- --check` remains a separate repository-wide check; existing formatting drift must be reported rather than silently replaced by a broad formatter rewrite.
- S96 packaged evidence is recorded in `artifacts/tauri-e2e/s96-runtime-contract.txt`, `artifacts/tauri-e2e/s96-final-installed-verification.txt`, `artifacts/tauri-e2e/s96-final-dmg-verification.txt`, and the canonical DMG under `artifacts/releases/`.

## Redaction contract

- Redact is a source-coordinate annotation with two endpoints and the same meaningful-size, hit-test, move, resize, and undo/redo semantics as Rectangle.
- The live preview must draw Redact as an opaque `#000000` fill with no dependency on the user-selected annotation color.
- The export compositor must call `fillRect` for Redact before Copy, Save, Drag, or Crop output is persisted; redaction must be present in the rasterized result and must not mutate the unredacted source capture.
- A Redact regression must assert normalized reverse-drag geometry, opaque fill coordinates, and the real App Copy path.

## S97 evidence contract

- Focused Redact evidence is the geometry/renderer/App harness: 22 tests pass, including hit-test/resize, opaque black rasterization, and Copy through the real editor.
- S97 packaged evidence is recorded in `artifacts/tauri-e2e/s97-runtime-contract.txt`, `artifacts/tauri-e2e/s97-final-installed-verification.txt`, `artifacts/tauri-e2e/s97-final-dmg-verification.txt`, and the canonical DMG under `artifacts/releases/`. These checks do not substitute for physical pointer redaction or public Apple release acceptance.

## S98 evidence contract

- The real App harness must prove that `Clear history` removes all Recent captures restore buttons while preserving the current editor image and reporting an actionable status; the control must remain disabled during capture.
- S98 focused App coverage is 16/16; combined Redact/App focused coverage is 22/22; the complete frontend suite is 68/68 across 15 files. Rust coverage remains 39/39 with `cargo check` and Clippy clean.
- S98 packaged evidence is recorded in `artifacts/tauri-e2e/s98-runtime-contract.txt`, `artifacts/tauri-e2e/s98-final-installed-verification.txt`, `artifacts/tauri-e2e/s98-final-dmg-verification.txt`, and the byte-identical canonical arm64 DMG under `artifacts/releases/`. These checks do not substitute for physical Accessibility-enabled interaction or public Apple release acceptance.

## S99 evidence contract

- The native capture path must evaluate the non-prompting parent Screen Recording preflight after acquiring the activity guard but before hiding the editor. A denied result returns the existing actionable permission message and does not start a hide/restore transition.
- Runtime-contract mode remains an explicit test-only exception so the packaged lifecycle contract still covers hide, native action, restore, focus, and activity release.
- S99 evidence is recorded in `artifacts/tauri-e2e/s99-runtime-contract.txt`, `artifacts/tauri-e2e/s99-final-installed-verification.txt`, `artifacts/tauri-e2e/s99-final-dmg-verification.txt`, and the byte-identical canonical arm64 DMG. The focused Rust regression proves the decision boundary; it does not substitute for a physical denied-permission UI run.

## S100 evidence contract

- The real App harness must prove that the editor's focus listener ignores blur and performs exactly one non-prompting `screen_capture_permission_status` refresh on focus, publishing the returned status.
- The refresh must skip while a native operation is active and use the existing status epoch so a late background response cannot overwrite a newer capture, permission, import, or export status.
- S100 evidence is recorded in `artifacts/tauri-e2e/s100-runtime-contract.txt`, `artifacts/tauri-e2e/s100-final-installed-verification.txt`, `artifacts/tauri-e2e/s100-final-dmg-verification.txt`, `artifacts/tauri-e2e/s100-release-rejection.txt`, and the byte-identical canonical arm64 DMG. These checks do not substitute for physical TCC/Accessibility acceptance or public Apple release acceptance.

## S101 evidence contract

- The exact installed arm64 bundle and its bundled selector must share the stable local `ShotEye Local Development` authority when that identity is available; local continuity remains explicitly separate from Developer ID trust.
- `scripts/verify_app.sh --launch --report artifacts/tauri-e2e/s101-baseline-installed-verification.txt` is the authoritative local baseline for this audit. It must report one exact `shoteye` process, strict bundle/helper signatures, helper permission and display-read success, native self-test success, and mounted-DMG/canonical-DMG parity.
- A locked desktop or denied Accessibility controller is an acceptance boundary, not a physical UI pass. `artifacts/tauri-e2e/s101-physical-acceptance-boundary.txt` records this distinction; physical toolbar, pointer, shortcut, Clipboard/Save, Finder-drag, and secondary-display claims require a later unlocked, Accessibility-enabled run.

## S102 evidence contract

- The canonical arm64 DMG must be byte-identical to the just-produced architecture/version-specific Tauri DMG after a package refresh.
- The exact installed `/Applications/ShotEye.app` bundle and its mounted DMG payload must pass the same local verifier, including stable local app/helper authority, helper permission/display-read, native self-tests, and one-process launch.
- Package-refresh evidence remains local-only. It does not promote a locked-session or Accessibility-denied environment to physical UI acceptance, and it does not satisfy Developer ID/Gatekeeper/notarization requirements.

## S103 evidence contract

- `scripts/verify_ui_smoke.sh` must target `/Applications/ShotEye.app`, enforce one exact `shoteye` process, validate the app's strict signature, and inspect accessible product controls and application menus through `System Events`.
- Exit `0` with `Result: PASS` means the accessible editor surface was observed. Exit `2` with `Result: BLOCKED` means the test environment cannot provide Accessibility or an unlocked desktop; this is not a product pass or failure claim.
- The harness must not invoke permission requests or destructive exports. Physical capture, shortcut, Clipboard/Save/Finder-drag, and secondary-display acceptance remain separate tests requiring operator-enabled permissions.

## S105 evidence contract

- With Accessibility available, the UI smoke harness must successfully click `Rectangle`, `Select`, `Pin ShotEye`, and `Unpin ShotEye` after accessible-name discovery; these clicks are the representative regression for the historical non-clickable-toolbar symptom.
- When Accessibility is unavailable or the desktop is locked, the harness must stop before the click phase, return exit `2`, and write `Result: BLOCKED`; a blocked run must never be reported as click acceptance.

## S106 evidence contract

- The focus-driven permission refresh must be single-flight: while one non-prompting `screen_capture_permission_status` request is pending, additional focus notifications must not start another request.
- The in-flight guard must release on success, rejection, and component disposal; status commits remain protected by the existing status epoch so a late refresh cannot overwrite a newer user action.
- The App regression must hold the first refresh open, fire duplicate focus events, and assert exactly one new IPC call before resolving it.

## S107 evidence contract

- `scripts/verify_ui_smoke.sh --capture-cancel` is the only mode that invokes `Capture area`; the default harness must remain non-destructive.
- When prerequisites are available, the opt-in mode must observe the exact packaged `ShotEyeSelector`, send Escape, observe its exit, and verify the ShotEye editor window is visible after cancellation.
- Missing Accessibility, a locked desktop, or a failed native Screen Recording preflight must return exit `2` with `Result: BLOCKED`; these states must not be reported as selector failures or lifecycle passes.
- A bundle-identifier lookup is not a valid System Events process target in this harness. Use the actual packaged executable process name `shoteye`, while retaining the bundle identifier check in package verification.

## S108 evidence contract

- If the bundled selector's non-prompting Screen Recording probe returns an explicit denial, capture must return an actionable permission error without invoking `/usr/sbin/screencapture`.
- An inconclusive probe or recoverable helper launch failure may still use the system selector fallback; an explicit denial and a selector timeout must not start a second capture path.
- The error presented to the user must say that ShotEye will not open another capture prompt until the exact installed app is authorized and relaunched.
- The dispatch contract must be covered by focused Rust tests and the fixed code must be present in the installed app and canonical DMG before the change is considered packaged.

## S109 evidence contract

- `screen_capture_permission_status` must remain non-prompting and run the bounded bundled-selector probe off the UI command thread.
- If the parent preflight is granted and the bundled selector is explicitly denied, the returned status must identify the parent/helper mismatch and provide exact relaunch guidance; it must not imply that a generic system setting is sufficient.
- If the helper probe is inconclusive, the status must say so while preserving the safe system-selector fallback behavior.
- Permission diagnostics must be covered by pure tests and present in the installed arm64 bundle before packaging evidence is refreshed.

## S110 evidence contract

- The editor status footer must use an auto-growing grid row with responsive wrapping so long permission, capture, and restoration messages remain visible at narrow and wide window sizes.
- The status footer must expose `role="status"` and `aria-live="polite"`; the real App harness must assert both attributes.
- S110 evidence is recorded in `artifacts/tauri-e2e/s110-runtime-contract.txt`, `artifacts/tauri-e2e/s110-final-installed-verification.txt`, `artifacts/tauri-e2e/s110-final-dmg-verification.txt`, `artifacts/tauri-e2e/s110-physical-ui-smoke.txt`, and `artifacts/tauri-e2e/s110-capture-cancel-physical-ui-smoke.txt`.
- Local package/runtime evidence does not substitute for Accessibility-enabled physical toolbar, selector, shortcut, Clipboard/Save, Finder-drag, or secondary-display acceptance; both S110 physical runs are explicitly blocked by `-25211`.

## S111 evidence contract

- Tauri `tauri://drag-drop` payloads must be treated as untrusted input: accept only the first supported PNG, JPEG, or TIFF path and fail closed for malformed, empty, or unsupported path lists.
- A supported Finder drop must use the same guarded `open_image` command and canonical capture state as the Open dialog; it must preserve dimensions and make the image available to annotations, Copy, Save, and Drag.
- Drop listeners must be cleaned up with the component lifecycle, and the editor must expose a visible drop affordance while a supported image is being dragged over it.
- S111 evidence is recorded in `artifacts/tauri-e2e/s111-runtime-contract.txt`, `artifacts/tauri-e2e/s111-final-installed-verification.txt`, and `artifacts/tauri-e2e/s111-final-dmg-verification.txt`. Unit/component tests do not substitute for physical Finder drag acceptance.

## S112 evidence contract

- Pixelate must be a first-class source-coordinate annotation with the same select, move, resize, undo/redo, crop, Copy, Save, and Drag integration as other rectangle-like annotations.
- The live preview must visibly obscure the selected region. Export composition must replace every pixelate block with one source color before persistence; if `getImageData` is unavailable, it must fail closed to an opaque black block.
- The real App harness must prove the Pixelate tool creates one annotation and reaches the shared `store_rendered_capture` → Copy path. Renderer tests must prove block replacement changes source pixels and the privacy fallback is opaque.
- S112 evidence is recorded in `artifacts/tauri-e2e/s112-runtime-contract.txt`, `artifacts/tauri-e2e/s112-final-installed-verification.txt`, and `artifacts/tauri-e2e/s112-final-dmg-verification.txt`. These local checks do not substitute for Accessibility-enabled physical interaction or public Apple release gates.

## S113 evidence contract

- Blur must be a first-class source-coordinate annotation with the same select, move, resize, undo/redo, crop, Copy, Save, and Drag integration as other rectangle-like annotations.
- The live preview must blur only the selected region. Export composition must apply a bounded blur to source pixels before persistence; if `getImageData` is unavailable, it must fail closed to an opaque black block.
- The real App harness must prove the Blur tool creates one annotation and reaches the shared `store_rendered_capture` → Copy path. Renderer tests must prove a sharp source boundary is averaged and the privacy fallback is opaque.
- `scripts/verify_ui_smoke.sh` must include Pixelate and Blur in its accessible-control inventory. S113 evidence is recorded in `artifacts/tauri-e2e/s113-runtime-contract.txt`, `artifacts/tauri-e2e/s113-final-installed-verification.txt`, `artifacts/tauri-e2e/s113-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s113-physical-ui-smoke.txt`.

## S114 evidence contract

- The native Tools menu must expose Select, Crop, Arrow, Rectangle, Text, Draw, Redact, Pixelate, and Blur with unique action IDs.
- Each Tools menu callback must route through the current React tool-selection dispatcher, clear transient annotation interaction state, and reject tool changes while a native capture is active without creating a second command path.
- The menu-model tests must cover the complete Tools action inventory, and the real App harness must invoke at least one recorded native Tools callback and observe the corresponding toolbar state change.
- S114 evidence is recorded in `artifacts/tauri-e2e/s114-runtime-contract.txt`, `artifacts/tauri-e2e/s114-final-installed-verification.txt`, `artifacts/tauri-e2e/s114-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s114-physical-ui-smoke.txt`. Local package evidence does not substitute for Accessibility-enabled physical menu interaction or public Apple release gates.

## S115 evidence contract

- `⌘⇧R` and `⌃⇧R` must map to Repeat Last Capture in the shared editor shortcut helper; unrelated `⌘R` and Option-modified chords must remain available to their existing platform/text-entry behavior.
- The real App harness must dispatch a `⌘⇧R` key event and observe exactly one `repeat_last_capture` IPC request, a valid canonical preview, and an actionable terminal status through the existing exclusive capture lane.
- S115 evidence is recorded in `artifacts/tauri-e2e/s115-runtime-contract.txt`, `artifacts/tauri-e2e/s115-final-installed-verification.txt`, `artifacts/tauri-e2e/s115-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s115-physical-ui-smoke.txt`. Local event/package evidence does not substitute for Accessibility-enabled physical shortcut invocation or public Apple release gates.

## S116 evidence contract

- The toolbar Repeat Last Capture control must visibly show `⌘⇧R`, expose `aria-keyshortcuts="Meta+Shift+R"`, and provide a concise tooltip without changing its accessible name or guarded action.
- The native Capture menu's Repeat Last Capture item must use `CmdOrCtrl+Shift+R` and delegate through the same current React action ref as the toolbar and DOM shortcut.
- Menu-model coverage must assert the accelerator, and the real App harness must assert the toolbar metadata and visible shortcut hint.
- S116 evidence is recorded in `artifacts/tauri-e2e/s116-runtime-contract.txt`, `artifacts/tauri-e2e/s116-final-installed-verification.txt`, `artifacts/tauri-e2e/s116-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s116-physical-ui-smoke.txt`. Local event/package evidence does not substitute for Accessibility-enabled physical interaction or public Apple release gates.

## S117 evidence contract

- `repeatCaptureShortcut` is the single source for the Repeat Last Capture registration string; the native menu accelerator derives from it, and the toolbar derives its display and `aria-keyshortcuts` values from it.
- The shortcut-display tests must cover registration, native-menu, and ARIA representations together, while the real App test must continue to verify the rendered toolbar metadata and visible hint.
- S117 evidence is recorded in `artifacts/tauri-e2e/s117-runtime-contract.txt`, `artifacts/tauri-e2e/s117-final-installed-verification.txt`, `artifacts/tauri-e2e/s117-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s117-physical-ui-smoke.txt`. Local event/package evidence does not substitute for Accessibility-enabled physical interaction or public Apple release gates.

## S118 evidence contract

- Open, Paste, Copy, Save, Undo, Redo, and Repeat toolbar controls must expose visible macOS shortcut hints, concise tooltips, and valid `aria-keyshortcuts` values without changing their accessible names or guarded action handlers.
- Native menu accelerators and toolbar hints must derive from one shared shortcut contract so registration, display, and accessibility representations cannot drift.
- The real App harness must assert all primary toolbar metadata and the shortcut contract tests must assert the platform-neutral native-menu forms.
- S118 evidence is recorded in `artifacts/tauri-e2e/s118-runtime-contract.txt`, `artifacts/tauri-e2e/s118-final-installed-verification.txt`, `artifacts/tauri-e2e/s118-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s118-physical-ui-smoke.txt`. Local event/package evidence does not substitute for Accessibility-enabled physical interaction or public Apple release gates.

## S88 evidence contract

- The S88 component harness covers the real React capture entry point with only Tauri/native boundaries mocked: pending capture status, single-flight re-entry protection, rejected capture recovery, and cancellation-result recovery.
- Local packaged evidence for S88 is recorded in `artifacts/tauri-e2e/s88-runtime-contract.txt`, `artifacts/tauri-e2e/s88-final-installed-verification.txt`, and `artifacts/tauri-e2e/s88-final-dmg-verification.txt`. These checks do not substitute for physical Accessibility-enabled UI, real pointer selection, secondary-display, or Apple release acceptance.

## S119 evidence contract

- Release mode must use `SHOT_EYE_SIGNING_IDENTITY` and fail before packaging when it is absent; local mode remains explicitly non-public.
- A release app archive must be submitted to notarization, stapled to the `.app`, and validated before `hdiutil create` runs. The generated DMG must then be submitted, stapled, validated, and only then copied to `artifacts/releases/`.
- The release-order regression must assert both helper command order and the package script's app-before-DMG-before-canonical-copy order without contacting Apple services.
- S119 evidence is recorded in `artifacts/tauri-e2e/s119-release-rejection.txt`, `artifacts/tauri-e2e/s119-runtime-contract.txt`, `artifacts/tauri-e2e/s119-final-installed-verification.txt`, `artifacts/tauri-e2e/s119-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s119-physical-ui-smoke.txt`. Local evidence does not substitute for physical Accessibility-enabled interaction or public Apple release acceptance.

## S120 evidence contract

- An authorized bundled selector must make area capture available even when the parent Tauri preflight is stale or false; explicit selector denial and an inconclusive probe with no parent grant must still stop before hiding the editor.
- The effective permission check must use the bundled selector only for area capture; window and full-screen capture must continue to use the parent/system capture path.
- The user-facing status must describe area readiness without exposing internal preflight terminology.
- S120 evidence is recorded in `artifacts/tauri-e2e/s120-runtime-contract.txt`, `artifacts/tauri-e2e/s120-final-installed-verification.txt`, and `artifacts/tauri-e2e/s120-final-dmg-verification.txt`. Physical interaction and public Apple release evidence remain separate requirements.

## S125 canonical launch contract

- `script/build_and_run.sh`, `scripts/verify_app.sh`, and `scripts/verify_ui_smoke.sh` must open only the freshly installed `/Applications/ShotEye.app` with `open -a`.
- The supported scripts must not contain `/usr/bin/open -n`; an explicit multi-instance launch would undermine the single-instance and TCC identity guarantees.
- The architecture-specific Tauri bundle remains the only supported build output. Any stale unqualified generated `.app` is outside the supported launch path and should be moved recoverably before package acceptance.
- `scripts/test_canonical_launch.sh` is the focused regression for these invariants. S125 package reports are recorded under `artifacts/tauri-e2e/s125-*`; they do not substitute for Accessibility-enabled physical interaction or public Apple release gates.

## S126 package-time stale-bundle contract

- `scripts/package_app.sh` must inspect the unqualified `tauri-app/src-tauri/target/release/bundle/macos/ShotEye.app` path before packaging the architecture-specific target.
- If the stale bundle exists and its `shoteye` executable is not running, packaging must move it to a recoverable temporary archive and report that path. If it is running, packaging must fail closed without moving it.
- `scripts/verify_app.sh` must fail closed if the same unqualified bundle is present during installed or mounted-DMG verification.
- `scripts/test_canonical_launch.sh` must cover the package-time guard as well as the `open -a` launch contract. S126 reports are recorded in `artifacts/tauri-e2e/s126-runtime-contract.txt`, `artifacts/tauri-e2e/s126-final-installed-verification.txt`, `artifacts/tauri-e2e/s126-final-dmg-verification.txt`, and `artifacts/tauri-e2e/s126-physical-ui-smoke.txt`.

## S142 stable Accessibility and shortcut-conflict contract

- `scripts/verify_ui_smoke.sh` must attach to exactly one `/Applications/ShotEye.app` process and prefer `scripts/shoteye_ax_driver.swift` for complete AX-tree discovery and reversible toolbar activation.
- The smoke report must identify `direct-ax` versus the `system-events-or-native-menu` fallback and classify unavailable Accessibility as `BLOCKED`.
- `scripts/test_shortcut_conflict_fixture.sh --check-exclusive` must prove that its temporary registration is exclusive before a conflict acceptance can make a product claim. Duplicate Carbon reservations are an environment prerequisite block, not a ShotEye failure.
- `scripts/test_accessibility_shortcut_conflict.sh` must reset the persisted shortcut before the run, enforce fixture cleanup, and report conflict/reset evidence only after exclusive ownership is proven.

## S143 shortcut transaction contract

- Shortcut replacement must register the requested binding before removing the prior binding.
- If requested registration fails, the previous binding and its registered state must remain unchanged.
- If prior-binding removal fails, the requested binding must be unregistered and the previous binding/state retained.
- Only a fully accepted replacement may update the canonical current shortcut.

## S146 bounded Accessibility automation contract

- Every `osascript` call in packaged UI acceptance must have a bounded timeout and must produce a terminal PASS, FAIL, or BLOCKED result.
- A cancellation acceptance must prove selector exit, editor restoration, and cleanup of the exact selector process; an observation hang must never be reported as capture success.

## S147 physical area-capture contract

- Installed acceptance must drive Capture Area through the actual accessible toolbar control, observe the bundled selector, and complete a real desktop drag.
- Copy Capture must yield a PNG with a valid signature and readable dimensions; a representative visual inspection must confirm the copied primary-display image is upright.

## S148 repeatable physical area-capture contract

- `scripts/test_physical_area_capture.sh` must target only `/Applications/ShotEye.app`, reject missing or invalidly signed bundles, and require exactly one canonical process.
- The acceptance path must invoke the accessible `Capture area` control, observe and clear the packaged `ShotEyeSelector`, complete the checked-in HID drag, invoke `Copy capture`, and write clipboard PNG data to an explicit artifact path.
- A passing report must include signature, dimensions, hash, artifact byte count, and scope. It proves only primary-display toolbar capture and Copy; it does not prove secondary-display, save/reopen pixel equivalence, shortcut conflict, or public Apple distribution trust.
- The harness must refuse caller-supplied output paths outside the project-owned `artifacts/tauri-e2e` directory before removing a prior artifact.

## S151 shortcut-conflict evidence boundary

- The installed product's Tauri global-shortcut dependency and the test fixture both use Carbon `RegisterEventHotKey` for ordinary keyboard shortcuts on macOS.
- When the fixture's two-process exclusivity probe accepts the same chord twice, external conflict acceptance is `BLOCKED`; changing only to the product dependency is not an alternative registration boundary.
- Product transaction tests remain the authoritative proof for registration rejection/rollback until an independently exclusive owner is available.

## S127 mounted-DMG launch contract

- When `scripts/verify_app.sh --dmg ... --launch` is requested, the verifier must stop only the exact `/Applications/ShotEye.app/Contents/MacOS/shoteye` test process before launching the same-identifier mounted payload.
- Process matching must canonicalize macOS temporary paths so `/var/...` and `/private/var/...` identify the same executable; cleanup must terminate the exact mounted payload process before detaching the DMG.
- The mounted launch path must write a non-empty report and leave no ShotEye DMG volume mounted or mounted-payload process running. S127 evidence is `artifacts/tauri-e2e/s127-dmg-launch-verification.txt`.

## S128 capture orientation and toolbar sizing contract

- The native compositor must not apply an additional y-axis reflection when drawing `CGDisplayCreateImage` results. Captured and exported PNGs must preserve the source display's visual top-to-bottom orientation.
- The helper's mixed-DPI and capture-output self-tests must assert top bands at the written PNG's top rows and bottom bands at its bottom rows, including multi-display seams and opaque coverage.
- Toolbar SVG icons must render at 16px square while their buttons retain at least the existing 40px interaction target and accessible labels.
- S128 evidence must include focused helper self-tests, frontend/build checks, and the exact packaged installed/DMG verification before the canonical download is refreshed. Physical pointer-selection evidence remains a separate gate.

## S129 packaged capture acceptance contract

- The packaged UI smoke harness must verify the exact installed process, signature, application menus, and reversible tool selection. If the current WKWebView does not expose DOM button roles to System Events, it must use the native `Tools` menu and record that WebView Accessibility limitation explicitly rather than failing on assumed button names.
- The opt-in capture-cancellation smoke must invoke `Capture Area` through the native `Capture` menu, observe the exact bundled `ShotEyeSelector` process, send Escape, verify the selector exits, and verify the restored ShotEye window is main and not minimized.
- A packaged success acceptance may drive the selector with a real desktop HID drag, then must validate the result through ShotEye's own Copy path and a PNG signature/dimension check. S129 evidence is `artifacts/tauri-e2e/s129-capture-cancel-smoke.txt`, `s129-physical-ui-menu-smoke.txt`, and `s129-capture-success.png`.
- Native-menu/HID acceptance must not be reported as physical toolbar pointer, global shortcut, Finder-drop, secondary-display, Developer ID, Gatekeeper, or notarization evidence.

## S130 nested toolbar Accessibility contract

- The packaged UI smoke harness must search the complete AX tree under the ShotEye window's WebView, not only direct window children. Toolbar controls may be descendants of `AXWebArea`; the Pin control may be represented as `AXCheckBox`.
- When the nested toolbar tree is available, the smoke must verify the required controls and exercise reversible toolbar clicks for `Rectangle` and `Select`. If it is unavailable, the report must identify the WebView Accessibility boundary and use the native menu path without claiming toolbar acceptance.

## S131 toolbar capture acceptance contract

- The installed-package acceptance path must click the actual `Capture area` toolbar control, observe the bundled selector, drive a real HID selection, verify selector exit and editor restoration, then use ShotEye's Copy path to validate a non-empty PNG with dimensions. S131 evidence is `artifacts/tauri-e2e/s131-toolbar-capture-success.txt` and `s131-toolbar-capture-success.png`.
- One-display toolbar capture evidence must not be generalized to global shortcut, Finder-drop, secondary-display, Developer ID, Gatekeeper, or notarization acceptance.

## S132 global shortcut acceptance contract

- The installed package must route the default capture shortcut while another application is frontmost, then preserve selector cancellation and editor restoration.
- The installed shortcut control must accept a valid custom modifier combination, route that binding while another application is frontmost, and restore the default binding through its reset control. S132 evidence is `artifacts/tauri-e2e/s132-shortcut-acceptance.txt`.
- This acceptance must not be generalized to conflict behavior with an unrelated registered shortcut, alternate keyboard layouts, Finder-drop, secondary-display, Developer ID, Gatekeeper, or notarization behavior.

## S135/S137 orientation and Finder drag-out contract

- The native compositor must preserve the display image's visual top-to-bottom order; a real one-display area capture copied from the exact installed package must remain upright and must validate as a non-empty PNG with dimensions.
- The Drag toolbar action must pass the originating WebView pointer position through the Tauri command boundary. The AppKit bridge must convert WebView client coordinates according to the view's flipped state and create its synthetic mouse-down event in the initiating window's base coordinate system.
- A staged Finder file URL must remain readable through asynchronous Finder consumption after `draggingSession:endedAtPoint:operation:`; managed Rust drag state owns the private staging location and cleans it when ShotEye exits.
- S137 evidence is `artifacts/tauri-e2e/s137-finder-drop-acceptance.txt`, `artifacts/tauri-e2e/s137-finder-drop/ShotEye Capture.png`, and `artifacts/tauri-e2e/s135-orientation-acceptance.txt`. This proves one-display selection, Copy, and Finder drop for the local installed package; it does not prove secondary-display behavior or public Apple release trust.
## S138 Save acceptance contract

- The installed package must complete Capture area → physical selection → Save capture with one process and valid output.
- The saved file must have a PNG signature, non-zero size, and dimensions. Evidence: `artifacts/tauri-e2e/s138-save-acceptance.txt` and `artifacts/tauri-e2e/s138-tauri-save-acceptance.png`.
- Opening the saved file is smoke coverage; pixel-equivalence after reopen remains unproven when packaged WebView status is inaccessible.
## S139 release-gate contract

- `scripts/verify_app.sh --release` must reject a local/ad-hoc identity before claiming release readiness. The current installed build correctly fails closed because no Developer ID Application identity is present.
- Evidence: `artifacts/tauri-e2e/s139-release-gate-output.txt`.
## S140 package verification contract

- The exact installed app and canonical arm64 DMG must pass strict structure, helper self-tests, output-boundary checks, and one-process launch verification while release gates remain separately labeled.
- Evidence: `artifacts/tauri-e2e/s140-final-installed-verification.txt`.
## S141 external acceptance boundary

- A one-display host cannot satisfy the secondary-display contract; record the actual inventory rather than simulating a pass.
- Shortcut-conflict acceptance requires stable Accessibility automation and must be reported as unproven when the control cannot be driven reliably.

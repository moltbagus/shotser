# ShotEye World-Class macOS Release Plan

Status: ready for implementation after ce-plan handoff
Date: 2026-08-29
Project root: `/Users/colbert1/shoteye`
Chosen sprint: `S29-stable-capture-release`
Proposed branch: `codex/s29-stable-capture-release`
Rationale: close the highest-leverage gap first—the packaged app must complete a real capture and restore/export it reliably before additional editor polish has release value.

## Scope and operating constraints

- Work only inside `/Users/colbert1/shoteye` and treat it as the project root.
- Inspect evidence before changing code; reason from timing, process identity, TCC state, and package contents rather than accepting a plausible permission story.
- Keep the existing Tauri/React editor, Rust command boundary, and bundled AppKit selector unless evidence requires a focused change.
- Do not weaken macOS permission checks, silently request consent, or claim physical capture success without a valid PNG and an observable packaged-app result.
- Run focused frontend/Rust/native/package checks. Full network suites are out of scope.
- Commits, pushes, pull requests, Developer ID enrollment, notarization, and changes to macOS privacy settings remain separate operator-authorized actions.

## Current evidence

### Working evidence

- `/Applications/ShotEye.app` is the current packaged app and its React editor renders.
- The editor has passed packaged interaction checks for Open, Paste, Copy, Save, annotations, move/resize, Undo/Redo, and editor keyboard chords.
- The arm64 package builds, the bundled `Contents/Resources/native/ShotEyeSelector` exists, and strict `codesign --verify --deep --strict` passes.
- The Rust capture path preflights Screen Recording access and avoids repeating the macOS consent sheet when the exact build is unavailable.
- AppKit helper startup has been proven independently by its expected missing-argument error.

### Failing or unproven evidence

- The latest exact installed `com.moltbagus.shoteye.tauri` build has not completed a physical area drag after the rename; current TCC access is unavailable for this exact ad-hoc build.
- Full screen, Repeat Last Capture, Copy, and Save are therefore not proven for the latest identity after a real area selection.
- The local self-signed `ShotEye Local Development` identity produced a blank Tauri WebKit editor in packaged control testing, so it is not an acceptable workaround.
- No Apple `Developer ID Application` identity is available locally; durable permission continuity and notarized distribution remain external release dependencies.
- The desktop automation attachment still has stale resolution behavior for the previous Shotser bundle ID. This must be re-established against the new ShotEye bundle before independent acceptance.
- A secondary-display physical run is unproven unless a second display is connected and the exact installed bundle is authorized.

## Options considered

1. **Harden the current hybrid adapter (recommended).** Keep the bundled Swift/AppKit selector as primary, keep `screencapture` as fallback, preserve non-prompting preflight, stabilize the new ShotEye identity, and prove the packaged flow. Smallest risk and directly addresses the observed failure.
2. **Move immediately to ScreenCaptureKit.** Potentially stronger long-term pixel and multi-display control, but adds native API, entitlement, availability, and permission complexity before the current lifecycle and TCC evidence is closed.
3. **Remove the permission gate or retry capture until it works.** Rejected. It would recreate the repeated prompt/hanging behavior reported by the user and would make the app less safe.

## Implementation slices after handoff

### S29-A — Identity and process hygiene

- Make `ShotEye` the only active product identity in user-facing package metadata and active runtime paths.
- Verify `CFBundleIdentifier`, display name, executable, resource layout, and DMG name from the package actually installed at `/Applications/ShotEye.app`.
- Stop only the exact stale ShotEye/Shotser project processes before evaluation; do not use broad destructive process cleanup.
- Refresh the desktop acceptance harness attachment against `com.moltbagus.shoteye.tauri` and record the observed app state.

### S29-B — Permission-aware capture contract

- Keep capture, full-screen, and repeat operations non-prompting unless the explicit Permissions action is used.
- Confirm the bundled selector is resolved from `Contents/Resources/native/ShotEyeSelector`, returns success/cancel/error distinctly, and cannot fall through into a second selector after cancellation.
- Confirm all failure paths restore and focus the editor and leave the prior valid image/state intact unless a new capture succeeds.
- Keep the status message actionable and product-branded; no internal “Tauri diagnostic” wording.
- If code changes are needed, add focused regressions for preflight, stale-output rejection, cancellation, helper exit mapping, and repeated-click locking.

### S29-C — Packaged acceptance proof

- Build the React frontend, run focused frontend tests, run `cargo check` and Rust tests, compile the Swift helper, package arm64, install the exact bundle, and run strict signature/resource checks.
- Launch from the installed package and verify one foreground ShotEye instance with one native titlebar.
- With Screen Recording enabled for this exact installed app, drag an area on the primary display, validate PNG signature/dimensions, restore/focus the editor, then Copy and Save and verify the exported bytes.
- Press Escape during selection and verify the editor restores with a cancellation status; trigger the permission-failure path and verify one actionable in-app status without a consent-loop.
- Click Capture area repeatedly while capture is active and verify only one selector operation exists.
- If a second display is connected, perform one cross-display/secondary-display selection; otherwise record that hardware verification is pending instead of inferring it from command flags.

### S29-D — Release-readiness documentation

- After implementation, bump `PRD.md` and `spec.md` together according to the repository convention, append the sprint to `tasks/kanban.md` and `tasks/todo.md`, and append evidence-backed patterns to `learnings.md` and `tasks/lessons.md`.
- Update `TODO.md` with the remaining external prerequisites: exact-package Screen Recording authorization, Developer ID signing/notarization, and secondary-display/shortcut evidence.
- Keep artifacts under `/Users/colbert1/shoteye/artifacts/tauri-e2e/`; list every screenshot/report path and its file signature, size, and dimensions.
- Mark successful checks separately from operator-gated checks; never convert “package built” into “capture works.”

## Verification matrix

| Area | Proof | Pass condition |
| --- | --- | --- |
| Source | focused frontend + Rust tests | all touched-path tests green |
| Package | arm64 Tauri build | `.app` and DMG created; helper bundled |
| Signature | `codesign --verify --deep --strict` | exit 0 on the exact installed app |
| Runtime | launch + process inspection | ShotEye active, one process, one native titlebar |
| Permission denial | Capture area without exact TCC grant | no consent loop; actionable status; editor usable |
| Capture success | physical drag with exact TCC grant | valid PNG, dimensions reported, preview restored |
| Export | Copy + Save + reopen/inspect | valid PNG bytes and matching dimensions |
| Cancellation | Escape | editor restored and capture lock released |
| Concurrency | repeated Capture clicks | one active selector only |
| Multi-monitor | secondary display when available | selected pixels correspond to chosen display |

## Known release blockers

- A real Developer ID Application certificate and notarization credentials are not present in this environment. This cannot be manufactured safely by code.
- Physical Screen Recording authorization for the exact current package must be granted by the operator in macOS System Settings before the success-path acceptance can be run.
- Secondary-display proof depends on connected hardware.

## Handoff

This is a planning artifact only. No application code, package, permission setting, commit, or push is changed by this plan. Implementation begins in S29 after the plan handoff, with the permission and identity evidence above treated as explicit acceptance gates.

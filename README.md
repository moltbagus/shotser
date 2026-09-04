# ShotEye

ShotEye is a Tauri macOS screenshot utility for area, window, and fullscreen capture, fast annotation (including privacy-safe Redact, Pixelate, and Blur), session capture history, Finder image drop import, and local Copy/Save export.

The supported product is the Tauri application under [`tauri-app/`](tauri-app/). It uses React in WKWebView, Rust for capture and export boundaries, and a bundled Swift/AppKit selector for multi-monitor area capture.

Drop a PNG, JPEG, or TIFF from Finder onto the editor to open it; ShotEye validates the native path and uses the same guarded import workflow as the Open button. Press `⌘⇧R` to repeat the last successful capture.

The historical Swift `Shotser.app` bundle is archived under `legacy-swift/archived/` and is not a supported launch target. Packaging and verification fail closed if another application bundle is placed directly under the repository's ignored `dist/` directory, preventing stale duplicate apps from being mistaken for ShotEye.

## Develop

```sh
cd tauri-app
npm ci
npm test -- --run
npm run build
```

## Package a downloadable Apple Silicon build

```sh
./scripts/package_app.sh
```

On Apple Silicon this builds the arm64 [`ShotEye.app`](tauri-app/src-tauri/target/aarch64-apple-darwin/release/bundle/macos/ShotEye.app) and DMG at `tauri-app/src-tauri/target/aarch64-apple-darwin/release/bundle/dmg/ShotEye_0.1.0_aarch64.dmg`; Intel Macs use the matching `x86_64-apple-darwin` target.

For a public release, set `SHOT_EYE_SIGNING_IDENTITY` to the complete identity string printed by `security find-identity -v -p codesigning`, provide either the Apple ID or App Store Connect API-key notarization variables, and run `./scripts/package_app.sh --release`. The command fails closed unless Developer ID signing, Gatekeeper assessment, and stapled notarization all validate.

For a local launch and one-process smoke check:

```sh
./script/build_and_run.sh --verify
```

The root runner installs the freshly built bundle at `/Applications/ShotEye.app`
before opening or verifying it. This keeps the bundle used for testing identical
to the bundle selected in macOS Privacy & Security, avoiding stale-copy and
repeated-permission confusion. Any previous `/Applications/ShotEye.app` is
moved to a recoverable temporary backup before replacement.
The runner then focuses that installed bundle with `open -a`; it does not launch
an additional build-tree copy with `open -n`.
Packaging also archives an old unqualified generated `target/release` bundle
outside the build tree, or stops with an actionable message if that copy is
currently running.

To verify an already-installed package and its runtime evidence without rebuilding it:

```sh
./scripts/verify_app.sh --launch --report artifacts/tauri-e2e/local-installed-verification.txt
```

To verify the exact app embedded in a DMG, mount it read-only and run the same bundle, helper, signature, parity, and artifact checks:

```sh
./scripts/verify_app.sh --dmg tauri-app/src-tauri/target/aarch64-apple-darwin/release/bundle/dmg/ShotEye_0.1.0_aarch64.dmg --report artifacts/tauri-e2e/s49-dmg-verification.txt
```

Add `--launch` when validating that the mounted payload itself starts. The
verifier temporarily stops only the exact installed ShotEye test process, then
cleans up the mounted payload process before detaching the DMG.

Packaging creates the DMG directly with `hdiutil` so local builds do not depend on Finder automation. Each package run atomically refreshes the architecture-specific download under `artifacts/releases/` and verifies byte parity; the verifier rejects a built or requested DMG that differs from that canonical artifact. The verifier also runs the bundled selector's geometry, mixed-DPI compositor, crop-transform, visual-orientation, output-boundary, and noninteractive display-read self-tests.
Use `--report` to bind the exact app/helper/DMG/artifact SHA-256 values and dimensions to the acceptance run.
Release packaging notarizes and validates the app before creating the DMG, then notarizes and validates the DMG before refreshing the canonical artifact; release mode fails closed without a configured Developer ID identity.

Screen Recording permission is required for desktop capture. macOS may show this permission under `Screen & System Audio Recording`; ShotEye captures screen pixels only and does not record system audio. The app preflights access without repeatedly opening the consent prompt; a known-denied capture keeps the editor visible and shows the recovery guidance. Use its Permissions action to request consent and then relaunch the exact installed bundle. When the `ShotEye Local Development` certificate and private key are available, local packaging uses that stable identity for the app and selector; otherwise it falls back explicitly to ad-hoc evaluation signing. Neither local mode is a public release: Developer ID signing and notarization are still required.
For area capture, ShotEye also validates the bundled selector identity that reads the display. If that selector is authorized while the parent probe is stale, the app reports area capture as ready; explicit selector denial still fails closed without reopening a consent prompt. The package verifier also runs a permission-free helper output self-test through the real compositor and PNG writer for both the installed app and mounted DMG.

The latest verified Apple Silicon package is copied to [`artifacts/releases/ShotEye_0.1.0_aarch64.dmg`](artifacts/releases/ShotEye_0.1.0_aarch64.dmg). It is an ad-hoc local build, not a notarized public release.

The earlier Swift prototype is retained under [`legacy-swift/`](legacy-swift/) for reference only. It is not the supported product and the root scripts never build or launch it, preventing a second legacy screenshot app from being created accidentally.

See [research/shottr-feature-research.md](research/shottr-feature-research.md) for the feature inventory and [docs/plans/2026-08-29-shoteye-world-class-release-plan.md](docs/plans/2026-08-29-shoteye-world-class-release-plan.md) for the release gates.

# ShotEye development

ShotEye is a Tauri + React macOS screenshot utility. The supported product path is this directory; the native process is named `shoteye` and the packaged product is `ShotEye.app`.

## Local verification

From the repository root, run `./scripts/package_app.sh` to build the architecture-specific app and DMG. The root packager creates the DMG directly with `hdiutil`, avoiding Finder-only cosmetic automation. Use `./script/build_and_run.sh --verify` to launch the packaged app and assert that one ShotEye process is running, or `./scripts/verify_app.sh --dmg <path>` to verify the exact mounted DMG payload and native geometry/compositor/crop self-tests.

## Recommended IDE Setup

- [VS Code](https://code.visualstudio.com/) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)

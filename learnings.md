# Shotser Learnings

## 2026-08-19

- A visible macOS window is not proof of interactivity; `NSRunningApplication.isActive` must be checked.
- Activating only from a manually-created `NSWindow` can race app launch. Use an `NSApplicationDelegate` launch hook plus post-mount activation.
- Full-screen capture overlays must disable mouse events and close, not only order out, before presenting the editor.
- GitNexus is useful for tracing `ShotserApp -> CaptureModel -> EditorView -> ToolbarIconButton` control flow.
- WSL2 server sync cannot be assumed; verify SSH reachability before claiming cross-machine synchronization.
- A local app launch and a fresh extracted ZIP can differ; evaluate the distributed artifact, not only `dist/Shotser.app`.
- `NSRunningApplication.isActive` can remain false after `open -n`; repeated activation on launch and `applicationDidBecomeActive` closed the packaged-app gap.

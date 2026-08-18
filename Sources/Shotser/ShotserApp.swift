import SwiftUI
import AppKit
import Foundation

@main
struct ShotserApp: App {
    @StateObject private var model = CaptureModel()
    @StateObject private var shortcutManager = ShortcutManager()

    init() {
        let captureModel = CaptureModel()
        let manager = ShortcutManager()
        manager.start { captureModel.capture(.area) }
        _model = StateObject(wrappedValue: captureModel)
        _shortcutManager = StateObject(wrappedValue: manager)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let currentPID = ProcessInfo.processInfo.processIdentifier
            let instances = NSRunningApplication.runningApplications(withBundleIdentifier: "com.moltbagus.shotser")
                .sorted { $0.processIdentifier < $1.processIdentifier }
            if let keeper = instances.first, keeper.processIdentifier != currentPID {
                keeper.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                NSApplication.shared.terminate(nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if CommandLine.arguments.contains("--preview") {
                captureModel.showPreviewEditor(preview: true)
            } else {
                captureModel.showEditor()
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("Shotser", systemImage: "camera.viewfinder") {
            CaptureMenu(model: model, shortcutManager: shortcutManager)
        }
        .menuBarExtraStyle(.menu)

        WindowGroup("Shotser Editor") {
            EditorView(model: model)
                .frame(minWidth: 760, minHeight: 520)
        }

        Settings {
            ShortcutSettingsView(manager: shortcutManager)
        }
    }
}

struct CaptureMenu: View {
    @ObservedObject var model: CaptureModel
    @ObservedObject var shortcutManager: ShortcutManager

    var body: some View {
        Button("Capture Area") { model.capture(.area) }
            .onAppear { startShortcutMonitor() }
        Button("Capture Window") { model.capture(.window) }
        Button("Capture Fullscreen") { model.capture(.fullscreen) }
        Divider()
        Button("Repeat Last Capture") { model.repeatLastCapture() }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        Button("Open Image…") { model.openImage() }
            .keyboardShortcut("o", modifiers: [.command])
        Button("Import Clipboard Image") { model.importClipboardImage() }
            .keyboardShortcut("v", modifiers: [.command, .shift])
        Divider()
        Button("Open Editor") { model.showEditor() }
        Button("Quit Shotser") { NSApplication.shared.terminate(nil) }
    }

    private func startShortcutMonitor() {
        shortcutManager.start { model.capture(.area) }
    }
}

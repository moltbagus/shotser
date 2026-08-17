import SwiftUI

@main
struct ShotserApp: App {
    @StateObject private var model = CaptureModel()

    var body: some Scene {
        MenuBarExtra("Shotser", systemImage: "camera.viewfinder") {
            CaptureMenu(model: model)
        }
        .menuBarExtraStyle(.menu)

        WindowGroup("Shotser Editor") {
            EditorView(model: model)
                .frame(minWidth: 760, minHeight: 520)
        }
    }
}

struct CaptureMenu: View {
    @ObservedObject var model: CaptureModel

    var body: some View {
        Button("Capture Area") { model.capture(.area) }
        Button("Capture Window") { model.capture(.window) }
        Button("Capture Fullscreen") { model.capture(.fullscreen) }
        Divider()
        Button("Open Editor") { model.openEditor = true }
        Button("Quit Shotser") { NSApplication.shared.terminate(nil) }
    }
}

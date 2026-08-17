import AppKit
import Combine
import CoreGraphics

enum CaptureKind: String, CaseIterable, Identifiable {
    case area, window, fullscreen
    var id: String { rawValue }
}

@MainActor
final class CaptureModel: ObservableObject {
    @Published var image: NSImage?
    @Published var selectedTool: EditorTool = .select
    @Published var openEditor = false

    func capture(_ kind: CaptureKind) {
        // Integration point for ScreenCaptureKit and a transparent selection overlay.
        // Keeping this seam small lets capture permissions and UI evolve independently.
        openEditor = true
    }

    func save() {
        guard let image else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Shotser Screenshot.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }

    func copyToClipboard() {
        guard let image else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
}

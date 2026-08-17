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
    @Published var statusMessage: String?
    @Published var recognizedText = ""
    @Published var qrCodes: [String] = []

    private let captureService = CaptureService()
    private let visionService = VisionService()

    func capture(_ kind: CaptureKind) {
        openEditor = true
        do {
            image = try captureService.capture(kind)
            statusMessage = kind == .area
                ? "Full display captured. Area selection overlay is next."
                : nil
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func inspectTextAndQR() {
        guard let image else {
            statusMessage = "Capture an image before running OCR."
            return
        }
        Task { @MainActor in
            do {
                let result = try await visionService.inspect(image)
                recognizedText = result.text
                qrCodes = result.qrCodes
                if result.text.isEmpty && result.qrCodes.isEmpty {
                    statusMessage = "No text or QR code found."
                } else {
                    statusMessage = "OCR complete."
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(result.text, forType: .string)
                }
            } catch {
                statusMessage = "OCR failed: \(error.localizedDescription)"
            }
        }
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

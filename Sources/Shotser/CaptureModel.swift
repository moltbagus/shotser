import AppKit
import Combine
import CoreGraphics
import SwiftUI

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
    @Published var annotations: [Annotation] = []

    private let captureService = CaptureService()
    private let visionService = VisionService()
    private var selectionOverlay: SelectionOverlayController?
    private var lastCaptureKind: CaptureKind?
    private var lastAreaRect: CGRect?
    private weak var lastAreaScreen: NSScreen?
    private var previewWindow: NSWindow?

    func capture(_ kind: CaptureKind) {
        lastCaptureKind = kind
        if kind == .area {
            beginAreaCapture()
            return
        }
        do {
            image = try captureService.capture(kind)
            statusMessage = nil
            showEditor()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func showEditor() {
        selectionOverlay?.finish()
        selectionOverlay = nil
        openEditor = true
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let editor = NSApp.windows.first(where: { $0.title == "Shotser Editor" }) {
            editor.makeKeyAndOrderFront(nil)
        } else {
            showPreviewEditor()
        }
    }

    func showPreviewEditor(preview: Bool = false) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1440, height: 760), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = preview ? "Shotser Editor Preview" : "Shotser Editor"
        window.contentView = NSHostingView(rootView: EditorView(model: self))
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.closeButton)?.isEnabled = true
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isEnabled = true
        window.standardWindowButton(.zoomButton)?.isEnabled = true
        window.collectionBehavior = [.managed, .fullScreenAuxiliary]
        window.center()
        NSApp.setActivationPolicy(.regular)
        previewWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKey()
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.contentView?.isHidden = false
            window.contentView?.needsDisplay = true
        }
    }

    private func beginAreaCapture() {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else { return }
        let overlay = SelectionOverlayController(screen: screen, onSelection: { [weak self] rect in
            guard let self else { return }
            self.selectionOverlay?.finish()
            do {
                self.image = try self.captureService.captureArea(rect, on: screen)
                self.lastAreaRect = rect
                self.lastAreaScreen = screen
                self.statusMessage = nil
                self.showEditor()
            } catch {
                self.statusMessage = error.localizedDescription
            }
            self.selectionOverlay = nil
        }, onCancel: { [weak self] in
            self?.selectionOverlay?.finish()
            self?.selectionOverlay = nil
            self?.statusMessage = "Area capture cancelled."
        })
        selectionOverlay = overlay
        overlay.begin()
    }

    func repeatLastCapture() {
        guard let lastCaptureKind else {
            statusMessage = "There is no previous capture yet."
            return
        }
        if lastCaptureKind == .area, let rect = lastAreaRect, let screen = lastAreaScreen {
            do {
                image = try captureService.captureArea(rect, on: screen)
                statusMessage = nil
                showEditor()
            } catch { statusMessage = error.localizedDescription }
        } else {
            capture(lastCaptureKind)
        }
    }

    func openImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url, let loaded = NSImage(contentsOf: url) else {
            statusMessage = "Could not open that image."
            return
        }
        image = loaded
        annotations.removeAll()
        statusMessage = "Opened image."
        showEditor()
    }

    func importClipboardImage() {
        guard let pasted = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            statusMessage = "There is no image in the clipboard."
            return
        }
        image = pasted
        annotations.removeAll()
        statusMessage = "Imported clipboard image."
        showEditor()
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
        guard let source = image,
              let image = AnnotationRenderer.render(image: source, annotations: annotations) else {
            statusMessage = "Capture or open an image before saving."
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Shotser Screenshot.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        do {
            try png.write(to: url)
            statusMessage = "Saved screenshot."
        } catch {
            statusMessage = "Could not save screenshot: \(error.localizedDescription)"
        }
    }

    func copyToClipboard() {
        guard let image, let rendered = AnnotationRenderer.render(image: image, annotations: annotations) else {
            statusMessage = "Capture an image before copying."
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([rendered])
        statusMessage = "Copied screenshot to clipboard."
    }

    func addAnnotation(_ kind: AnnotationKind, start: CGPoint, end: CGPoint) {
        annotations.append(Annotation(kind: kind, start: start, end: end))
    }
}

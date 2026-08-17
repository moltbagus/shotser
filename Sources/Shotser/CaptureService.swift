import AppKit
import CoreGraphics

enum CaptureError: LocalizedError {
    case noDisplayImage
    case noWindowImage

    var errorDescription: String? {
        switch self {
        case .noDisplayImage: "Shotser could not read the display. Check Screen Recording permission in System Settings."
        case .noWindowImage: "Shotser could not capture that window. Check Screen Recording permission in System Settings."
        }
    }
}

struct CaptureService {
    func capture(_ kind: CaptureKind) throws -> NSImage {
        switch kind {
        case .fullscreen:
            return try captureDisplay()
        case .window:
            return try captureFrontmostWindow()
        case .area:
            // Area selection is intentionally a separate overlay slice. Capturing the
            // display here keeps the service useful while that UI is being added.
            return try captureDisplay()
        }
    }

    private func captureDisplay() throws -> NSImage {
        guard let screen = NSScreen.main,
              let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let image = CGDisplayCreateImage(displayID) else {
            throw CaptureError.noDisplayImage
        }
        return NSImage(cgImage: image, size: screen.frame.size)
    }

    private func captureFrontmostWindow() throws -> NSImage {
        let windowID = CGWindowID(NSApp.keyWindow?.windowNumber ?? 0)
        guard windowID != 0,
              let image = CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, [.bestResolution, .boundsIgnoreFraming]) else {
            throw CaptureError.noWindowImage
        }
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
}

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
            return try captureDisplay(on: NSScreen.main)
        case .window:
            return try captureFrontmostWindow()
        case .area:
            return try captureDisplay(on: NSScreen.main)
        }
    }

    func captureArea(_ rect: CGRect, on screen: NSScreen) throws -> NSImage {
        guard let displayImage = try? captureDisplay(on: screen),
              let cgImage = displayImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CaptureError.noDisplayImage
        }
        let scale = screen.backingScaleFactor
        let pixelRect = CGRect(x: rect.minX * scale,
                               y: (screen.frame.height - rect.maxY) * scale,
                               width: rect.width * scale,
                               height: rect.height * scale).integral
        guard let cropped = cgImage.cropping(to: pixelRect.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))) else {
            throw CaptureError.noDisplayImage
        }
        return NSImage(cgImage: cropped, size: rect.size)
    }

    private func captureDisplay(on screen: NSScreen?) throws -> NSImage {
        guard let screen,
              let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let image = CGDisplayCreateImage(displayID) else {
            throw CaptureError.noDisplayImage
        }
        return NSImage(cgImage: image, size: screen.frame.size)
    }

    private func captureFrontmostWindow() throws -> NSImage {
        let windowID = frontmostExternalWindowID()
        guard windowID != 0,
              let image = CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, [.bestResolution, .boundsIgnoreFraming]) else {
            throw CaptureError.noWindowImage
        }
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }

    private func frontmostExternalWindowID() -> CGWindowID {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return 0 }

        let ownName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        for window in windows {
            guard let owner = window[kCGWindowOwnerName as String] as? String,
                  owner != ownName,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let number = window[kCGWindowNumber as String] as? CGWindowID else { continue }
            return number
        }
        return 0
    }
}

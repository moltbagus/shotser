import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private final class SelectionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private func normalizedSelectionRect(from start: CGPoint, to end: CGPoint, minimumDimension: CGFloat = 2) -> CGRect? {
    let rect = CGRect(
        x: min(start.x, end.x),
        y: min(start.y, end.y),
        width: abs(end.x - start.x),
        height: abs(end.y - start.y)
    )
    guard rect.width >= minimumDimension, rect.height >= minimumDimension else { return nil }
    return rect
}

private struct SelectionInteractionState {
    private(set) var startPoint: CGPoint? = nil
    private(set) var currentPoint: CGPoint? = nil

    mutating func begin(at point: CGPoint) {
        startPoint = point
        currentPoint = point
    }

    mutating func update(to point: CGPoint) {
        guard startPoint != nil else { return }
        currentPoint = point
    }

    mutating func finish(at point: CGPoint) -> CGRect? {
        defer { cancel() }
        guard let startPoint else { return nil }
        return normalizedSelectionRect(from: startPoint, to: point)
    }

    mutating func cancel() {
        startPoint = nil
        currentPoint = nil
    }

    func selectionRect() -> CGRect? {
        guard let startPoint, let currentPoint else { return nil }
        return normalizedSelectionRect(from: startPoint, to: currentPoint)
    }
}

private func selectionInteractionSelfTestPassed() -> Bool {
    var forwardState = SelectionInteractionState()
    forwardState.begin(at: CGPoint(x: 10, y: 20))
    forwardState.update(to: CGPoint(x: 90, y: 120))
    let forward = forwardState.finish(at: CGPoint(x: 90, y: 120))

    var reverseState = SelectionInteractionState()
    reverseState.begin(at: CGPoint(x: 90, y: 120))
    reverseState.update(to: CGPoint(x: 10, y: 20))
    let reverse = reverseState.finish(at: CGPoint(x: 10, y: 20))

    var tinyState = SelectionInteractionState()
    tinyState.begin(at: CGPoint(x: 10, y: 20))
    let tooSmall = tinyState.finish(at: CGPoint(x: 11, y: 22))
    let thin = normalizedSelectionRect(from: CGPoint(x: 10, y: 20), to: CGPoint(x: 30, y: 21.99))

    var cancelledState = SelectionInteractionState()
    cancelledState.begin(at: CGPoint(x: 10, y: 20))
    cancelledState.update(to: CGPoint(x: 80, y: 90))
    cancelledState.cancel()

    return forward == CGRect(x: 10, y: 20, width: 80, height: 100)
        && reverse == forward
        && tooSmall == nil
        && thin == nil
        && tinyState.selectionRect() == nil
        && cancelledState.selectionRect() == nil
}

private final class SelectionView: NSView {
    var onSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?
    private var interaction = SelectionInteractionState()

    override var acceptsFirstResponder: Bool { true }

    func cancelInteraction() {
        interaction.cancel()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        interaction.begin(at: convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        interaction.update(to: convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let localRect = interaction.finish(at: convert(event.locationInWindow, from: nil)) else {
            needsDisplay = true
            return
        }
        onSelection?(localRect)
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelInteraction()
            onCancel?()
            return
        }
        super.keyDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.22).setFill()
        dirtyRect.fill()
        guard let localRect = interaction.selectionRect() else { return }
        NSColor.systemBlue.setStroke()
        let path = NSBezierPath(rect: localRect)
        path.lineWidth = 2
        path.stroke()
    }
}

/// Exercises the real AppKit event handlers without showing a panel or reading
/// display pixels. This catches regressions in event coordinate conversion,
/// responder readiness, gesture callbacks, and Escape cancellation.
private func selectionEventSelfTestPassed() -> Bool {
    let application = NSApplication.shared
    application.setActivationPolicy(.accessory)

    let panel = SelectionPanel(
        contentRect: NSRect(x: 100, y: 200, width: 300, height: 200),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    let view = SelectionView(frame: NSRect(origin: .zero, size: NSSize(width: 300, height: 200)))
    panel.contentView = view

    var selections: [CGRect] = []
    var cancellations = 0
    view.onSelection = { selections.append($0) }
    view.onCancel = { cancellations += 1 }

    func mouseEvent(_ type: NSEvent.EventType, at location: NSPoint, number: Int) -> NSEvent? {
        NSEvent.mouseEvent(
            with: type,
            location: location,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            eventNumber: number,
            clickCount: 1,
            pressure: 1
        )
    }

    let interactionReady = panel.canBecomeKey
        && view.acceptsFirstResponder
        && panel.makeFirstResponder(view)
    guard interactionReady,
          let firstDown = mouseEvent(.leftMouseDown, at: NSPoint(x: 20, y: 30), number: 1),
          let firstDrag = mouseEvent(.leftMouseDragged, at: NSPoint(x: 80, y: 90), number: 2),
          let firstUp = mouseEvent(.leftMouseUp, at: NSPoint(x: 80, y: 90), number: 3) else {
        panel.close()
        return false
    }
    view.mouseDown(with: firstDown)
    view.mouseDragged(with: firstDrag)
    view.mouseUp(with: firstUp)

    guard selections == [CGRect(x: 20, y: 30, width: 60, height: 60)],
          let secondDown = mouseEvent(.leftMouseDown, at: NSPoint(x: 160, y: 140), number: 4),
          let secondUp = mouseEvent(.leftMouseUp, at: NSPoint(x: 120, y: 100), number: 5),
          let escape = NSEvent.keyEvent(
              with: .keyDown,
              location: .zero,
              modifierFlags: [],
              timestamp: 0,
              windowNumber: panel.windowNumber,
              context: nil,
              characters: "",
              charactersIgnoringModifiers: "",
              isARepeat: false,
              keyCode: 53
          ) else {
        panel.close()
        return false
    }

    view.mouseDown(with: secondDown)
    view.mouseUp(with: secondUp)
    view.mouseDown(with: secondDown)
    view.keyDown(with: escape)
    panel.close()

    return selections == [
        CGRect(x: 20, y: 30, width: 60, height: 60),
        CGRect(x: 120, y: 100, width: 40, height: 40),
    ] && cancellations == 1
}

/// Returns false when a selection rectangle includes a physical gap between
/// offset displays. The selector can span connected screens, but it must not
/// return a successful PNG with transparent pixels that were never on a
/// display.
private func selectionIsFullyCovered(_ selection: CGRect, by screenFrames: [CGRect]) -> Bool {
    let selection = selection.standardized
    let epsilon: CGFloat = 0.01
    guard selection.width > epsilon, selection.height > epsilon else { return false }

    var xBoundaries = [selection.minX, selection.maxX]
    for frame in screenFrames {
        let intersection = frame.intersection(selection)
        guard !intersection.isNull, intersection.width > epsilon, intersection.height > epsilon else { continue }
        xBoundaries.append(intersection.minX)
        xBoundaries.append(intersection.maxX)
    }
    let boundaries = Array(Set(xBoundaries)).sorted()
    guard boundaries.count > 1 else { return false }

    for index in 0..<(boundaries.count - 1) {
        let left = boundaries[index]
        let right = boundaries[index + 1]
        guard right - left > epsilon else { continue }
        let sampleX = (left + right) / 2
        var intervals: [(lower: CGFloat, upper: CGFloat)] = []
        for frame in screenFrames where frame.minX <= sampleX + epsilon && frame.maxX >= sampleX - epsilon {
            let intersection = frame.intersection(selection)
            guard !intersection.isNull, intersection.width > epsilon, intersection.height > epsilon else { continue }
            intervals.append((intersection.minY, intersection.maxY))
        }
        intervals.sort { $0.lower < $1.lower }
        var coveredThrough = selection.minY
        for interval in intervals {
            guard interval.lower <= coveredThrough + epsilon else { return false }
            coveredThrough = max(coveredThrough, interval.upper)
            if coveredThrough >= selection.maxY - epsilon { break }
        }
        guard coveredThrough >= selection.maxY - epsilon else { return false }
    }
    return true
}

private func geometrySelfTestPassed() -> Bool {
    let left = CGRect(x: 0, y: 0, width: 100, height: 100)
    let right = CGRect(x: 100, y: 0, width: 100, height: 100)
    let lower = CGRect(x: 0, y: -100, width: 100, height: 100)
    let gap = CGRect(x: 0, y: 120, width: 100, height: 100)
    return selectionIsFullyCovered(CGRect(x: 10, y: 10, width: 180, height: 80), by: [left, right])
        && selectionIsFullyCovered(CGRect(x: 10, y: -90, width: 80, height: 180), by: [left, lower])
        && !selectionIsFullyCovered(CGRect(x: 10, y: 10, width: 80, height: 200), by: [left, gap])
        && !selectionIsFullyCovered(CGRect(x: -20, y: 10, width: 140, height: 80), by: [left])
}

private func makeBandedTestImage(width: Int, height: Int, top: CGColor, bottom: CGColor) -> CGImage? {
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    ) else { return nil }
    context.setFillColor(bottom)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.setFillColor(top)
    context.fill(CGRect(x: 0, y: CGFloat(height / 2), width: CGFloat(width), height: CGFloat(height - height / 2)))
    return context.makeImage()
}

private func pixelAlignedRect(_ rect: CGRect) -> CGRect {
    let minX = floor(rect.minX)
    let minY = floor(rect.minY)
    let maxX = ceil(rect.maxX)
    let maxY = ceil(rect.maxY)
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

private func makeRowMajorTestImage(width: Int, height: Int, pixel: (Int, Int) -> (UInt8, UInt8, UInt8, UInt8)) -> CGImage? {
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        for x in 0..<width {
            let offset = (y * width + x) * 4
            let value = pixel(x, y)
            bytes[offset] = value.0
            bytes[offset + 1] = value.1
            bytes[offset + 2] = value.2
            bytes[offset + 3] = value.3
        }
    }
    guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
}

private func displayCropRect(selection: CGRect, intersection: CGRect, screenFrame: CGRect, scale: CGFloat) -> CGRect {
    pixelAlignedRect(CGRect(
        x: (intersection.minX - screenFrame.minX) * scale,
        y: (screenFrame.maxY - intersection.maxY) * scale,
        width: intersection.width * scale,
        height: intersection.height * scale
    ))
}

private func cropDisplayImage(
    fullImage: CGImage,
    selection: CGRect,
    intersection: CGRect,
    screenFrame: CGRect,
    scale: CGFloat
) -> CGImage? {
    let localRect = displayCropRect(
        selection: selection,
        intersection: intersection,
        screenFrame: screenFrame,
        scale: scale
    )
    let imageBounds = CGRect(x: 0, y: 0, width: fullImage.width, height: fullImage.height)
    let cropRect = localRect.intersection(imageBounds)
    guard cropRect.width >= 1, cropRect.height >= 1 else { return nil }
    return fullImage.cropping(to: cropRect)
}

private func imagePixel(_ image: CGImage, x: Int, y: Int) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)? {
    guard x >= 0, y >= 0, x < image.width, y < image.height,
          let data = image.dataProvider?.data,
          let bytes = CFDataGetBytePtr(data) else { return nil }
    let offset = y * image.bytesPerRow + x * 4
    return (bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3])
}

private func composeCaptureImage(
    selection: CGRect,
    inputs: [(intersection: CGRect, image: CGImage)],
    outputScale: CGFloat
) -> CGImage? {
    guard outputScale > 0, selection.width > 0, selection.height > 0 else { return nil }
    let outputWidth = max(1, Int(ceil(selection.width * outputScale)))
    let outputHeight = max(1, Int(ceil(selection.height * outputScale)))
    guard let context = CGContext(
        data: nil,
        width: outputWidth,
        height: outputHeight,
        bitsPerComponent: 8,
        bytesPerRow: outputWidth * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    ) else { return nil }

    // Keep the default Quartz coordinate system when drawing CGDisplayCreateImage
    // results. The display image already has the correct visual orientation; an
    // additional y-axis reflection would mirror every captured PNG vertically.
    context.interpolationQuality = .none
    context.setFillColor(NSColor.clear.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))
    for input in inputs {
        let destination = pixelAlignedRect(CGRect(
            x: (input.intersection.minX - selection.minX) * outputScale,
            y: (input.intersection.minY - selection.minY) * outputScale,
            width: input.intersection.width * outputScale,
            height: input.intersection.height * outputScale
        ))
        context.draw(input.image, in: destination)
    }
    return context.makeImage()
}

private func mixedDPICompositorSelfTestPassed() -> Bool {
    let selection = CGRect(x: 0.25, y: 0.5, width: 100.25, height: 80.5)
    guard let bandedLeft = makeBandedTestImage(
        width: 50,
        height: 80,
        top: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
        bottom: CGColor(red: 0, green: 1, blue: 0, alpha: 1)
    ),
    let bandedRight = makeBandedTestImage(
        width: 100,
        height: 160,
        top: CGColor(red: 0, green: 0, blue: 1, alpha: 1),
        bottom: CGColor(red: 1, green: 1, blue: 0, alpha: 1)
    ),
    let composed = composeCaptureImage(
        selection: selection,
        inputs: [
            (CGRect(x: 0.25, y: 0.5, width: 50, height: 80.5), bandedLeft),
            (CGRect(x: 50.25, y: 0.5, width: 50.25, height: 80.5), bandedRight)
        ],
        outputScale: 2
    ) else { return false }
    guard composed.width == 201, composed.height == 161 else { return false }
    let isRed: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(red) > Int(green) + 100 && Int(red) > Int(blue) + 100
    }
    let isGreen: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(green) > Int(red) + 100 && Int(green) > Int(blue) + 100
    }
    let isBlue: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(blue) > Int(red) + 100 && Int(blue) > Int(green) + 100
    }
    let isYellow: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(red) > Int(blue) + 100 && Int(green) > Int(blue) + 100
    }
    // The selection's fractional origin and width exercise the explicit
    // floor/ceil policy used for both destination edges and output size.
    let topBandHeight = (composed.height + 1) / 2
    for y in 0..<composed.height {
        for x in 0..<composed.width {
            guard let pixel = imagePixel(composed, x: x, y: y), pixel.alpha > 240 else { return false }
            let expected: Bool
            if x < 100 {
                if y < topBandHeight {
                    expected = isRed(pixel.red, pixel.green, pixel.blue)
                } else {
                    expected = isGreen(pixel.red, pixel.green, pixel.blue)
                }
            } else {
                if y < topBandHeight {
                    expected = isBlue(pixel.red, pixel.green, pixel.blue)
                } else {
                    expected = isYellow(pixel.red, pixel.green, pixel.blue)
                }
            }
            guard expected else { return false }
        }
    }
    return true
}

private func captureCropTransformSelfTestPassed() -> Bool {
    let screenFrame = CGRect(x: 0, y: 0, width: 4, height: 4)
    let scale: CGFloat = 2
    let topSelection = CGRect(x: 1, y: 2, width: 2, height: 1)
    let bottomSelection = CGRect(x: 1, y: 0, width: 2, height: 1)
    guard let fullImage = makeRowMajorTestImage(width: 8, height: 8, pixel: { _, y in
        y < 4 ? (255, 0, 0, 255) : (0, 255, 0, 255)
    }),
    let top = cropDisplayImage(
        fullImage: fullImage,
        selection: topSelection,
        intersection: topSelection,
        screenFrame: screenFrame,
        scale: scale
    ),
    let bottom = cropDisplayImage(
        fullImage: fullImage,
        selection: bottomSelection,
        intersection: bottomSelection,
        screenFrame: screenFrame,
        scale: scale
    ),
    let topPixel = imagePixel(top, x: 0, y: 0),
    let bottomPixel = imagePixel(bottom, x: 0, y: 0) else { return false }

    guard displayCropRect(
        selection: topSelection,
        intersection: topSelection,
        screenFrame: screenFrame,
        scale: scale
    ) == CGRect(x: 2, y: 2, width: 4, height: 2),
    displayCropRect(
        selection: bottomSelection,
        intersection: bottomSelection,
        screenFrame: screenFrame,
        scale: scale
    ) == CGRect(x: 2, y: 6, width: 4, height: 2) else { return false }

    return top.width == 4 && top.height == 2
        && bottom.width == 4 && bottom.height == 2
        && topPixel.red > topPixel.green + 100
        && bottomPixel.green > bottomPixel.red + 100
        && topPixel.alpha == 255 && bottomPixel.alpha == 255
}

/// Exercises the real Core Graphics display-read boundary without showing a
/// selector or requesting consent. This is intentionally narrower than an
/// area-drag acceptance test: it proves the exact helper can obtain pixels
/// under the current TCC identity and reports a useful failure code when it
/// cannot.
private func displayReadSelfTestExitCode() -> Int32 {
    // Exit code 3 is reserved for a missing Screen Recording grant; a real
    // display-read or image-shape failure is an ordinary helper failure.
    guard CGPreflightScreenCaptureAccess() else { return 3 }
    guard let image = CGDisplayCreateImage(CGMainDisplayID()) else { return 1 }
    guard image.width > 0, image.height > 0, image.bytesPerRow >= image.width * 4 else { return 1 }
    return 0
}

private func writePNG(_ image: CGImage, to outputURL: URL) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else { return false }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}

/// Writes a deterministic, small PNG through the same compositor and ImageIO
/// writer used by the real selector. This is intentionally permission-free:
/// it proves the helper's output boundary without claiming a physical display
/// selection or exercising TCC.
private func captureOutputSelfTest(outputURL: URL) -> Bool {
    let leftFrame = CGRect(x: 0, y: 0, width: 4, height: 4)
    let rightFrame = CGRect(x: 4, y: 0, width: 4, height: 4)
    let selection = CGRect(x: 0, y: 0, width: 8, height: 4)
    guard selectionIsFullyCovered(selection, by: [leftFrame, rightFrame]),
          let left = makeBandedTestImage(
              width: 4,
              height: 4,
              top: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
              bottom: CGColor(red: 0, green: 1, blue: 0, alpha: 1)
          ),
          let right = makeBandedTestImage(
              width: 4,
              height: 4,
              top: CGColor(red: 0, green: 0, blue: 1, alpha: 1),
              bottom: CGColor(red: 1, green: 1, blue: 0, alpha: 1)
          ),
          let composed = composeCaptureImage(
              selection: selection,
              inputs: [
                  (intersection: leftFrame, image: left),
                  (intersection: rightFrame, image: right),
              ],
              outputScale: 1
          ),
          composed.width == 8,
          composed.height == 4,
          let leftTop = imagePixel(composed, x: 0, y: 0),
          let rightTop = imagePixel(composed, x: 4, y: 0),
          let leftBottom = imagePixel(composed, x: 0, y: 3),
          let rightBottom = imagePixel(composed, x: 4, y: 3) else { return false }

    let isGreen: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(green) > Int(red) + 100 && Int(green) > Int(blue) + 100
    }
    let isYellow: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(red) > Int(blue) + 100 && Int(green) > Int(blue) + 100
    }
    let isRed: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(red) > Int(green) + 100 && Int(red) > Int(blue) + 100
    }
    let isBlue: (UInt8, UInt8, UInt8) -> Bool = { red, green, blue in
        Int(blue) > Int(red) + 100 && Int(blue) > Int(green) + 100
    }
    guard leftTop.alpha > 240, rightTop.alpha > 240,
          leftBottom.alpha > 240, rightBottom.alpha > 240,
          isRed(leftTop.red, leftTop.green, leftTop.blue),
          isBlue(rightTop.red, rightTop.green, rightTop.blue),
          isGreen(leftBottom.red, leftBottom.green, leftBottom.blue),
          isYellow(rightBottom.red, rightBottom.green, rightBottom.blue) else { return false }

    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else { return false }
    CGImageDestinationAddImage(destination, composed, nil)
    guard CGImageDestinationFinalize(destination),
          let source = CGImageSourceCreateWithURL(outputURL as CFURL, nil),
          let written = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return false }
    return written.width == 8 && written.height == 4
}

private final class SelectorDelegate: NSObject, NSApplicationDelegate {
    let outputURL: URL
    private var overlay: NSPanel?
    private var selectionView: SelectionView?
    private var cursorPushed = false
    private var selectionStarted = false
    private var finished = false
    var exitCode = 1

    init(outputURL: URL) {
        self.outputURL = outputURL
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screens = NSScreen.screens
        guard let firstScreen = screens.first else {
            finish(code: 1)
            return
        }

        let unionFrame = screens.dropFirst().reduce(firstScreen.frame) { $0.union($1.frame) }
        let panel = SelectionPanel(
            contentRect: unionFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.hidesOnDeactivate = true
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let view = SelectionView(frame: NSRect(origin: .zero, size: unionFrame.size))
        view.onSelection = { [weak self, weak panel] localRect in
            guard let self, let panel else { return }
            guard !self.selectionStarted else { return }
            self.selectionStarted = true
            let globalRect = localRect.offsetBy(dx: unionFrame.minX, dy: unionFrame.minY)
            panel.ignoresMouseEvents = true
            // Let AppKit remove the overlay from the compositor before taking
            // display pixels. This prevents the dimming layer from entering
            // the resulting image and keeps the selector out of its own shot.
            panel.orderOut(nil)
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.finished else { return }
                self.capture(globalRect, screens: screens)
            }
        }
        view.onCancel = { [weak self] in
            self?.finish(code: 2)
        }
        panel.contentView = view
        overlay = panel
        selectionView = view

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(view)
        NSCursor.crosshair.push()
        cursorPushed = true
    }

    func applicationDidResignActive(_ notification: Notification) {
        guard !finished, !selectionStarted else { return }
        selectionView?.cancelInteraction()
        finish(code: 2)
    }

    private func capture(_ selection: CGRect, screens: [NSScreen]) {
        guard selection.width >= 2, selection.height >= 2 else {
            finish(code: 2)
            return
        }
        guard selectionIsFullyCovered(selection, by: screens.map(\.frame)) else {
            // Exit code 4 is handled by Rust as an actionable gap warning.
            finish(code: 4)
            return
        }
        guard CGPreflightScreenCaptureAccess() else {
            finish(code: 3)
            return
        }

        let expectedScreenCount = screens.reduce(into: 0) { count, screen in
            let intersection = selection.intersection(screen.frame)
            if !intersection.isNull, intersection.width >= 1, intersection.height >= 1 {
                count += 1
            }
        }
        let intersectingScreens = screens.compactMap { screen -> (NSScreen, CGRect, CGImage)? in
            let intersection = selection.intersection(screen.frame)
            guard !intersection.isNull, intersection.width >= 1, intersection.height >= 1,
                  let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
                  let fullImage = CGDisplayCreateImage(displayID) else {
                return nil
            }

            let scale = screen.backingScaleFactor
            guard let cropped = cropDisplayImage(
                fullImage: fullImage,
                selection: selection,
                intersection: intersection,
                screenFrame: screen.frame,
                scale: scale
            ) else {
                return nil
            }
            return (screen, intersection, cropped)
        }

        // Never report a successful screenshot with a transparent hole when a
        // display participating in the selection could not be read.
        guard expectedScreenCount > 0, intersectingScreens.count == expectedScreenCount else {
            finish(code: 1)
            return
        }

        let outputScale = intersectingScreens.map { $0.0.backingScaleFactor }.max() ?? 1
        let inputs = intersectingScreens.map { (intersection: $0.1, image: $0.2) }
        guard let outputImage = composeCaptureImage(
            selection: selection,
            inputs: inputs,
            outputScale: outputScale
        ), writePNG(outputImage, to: outputURL) else {
            finish(code: 1)
            return
        }
        finish(code: 0)
    }

    private func finish(code: Int32) {
        guard !finished else { return }
        finished = true
        exitCode = Int(code)
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
        overlay?.orderOut(nil)
        overlay?.close()
        NSApp.terminate(nil)
    }
}

let arguments = CommandLine.arguments
if arguments.contains("--self-test-selection") {
    exit(selectionInteractionSelfTestPassed() && selectionEventSelfTestPassed() ? 0 : 1)
}
if arguments.contains("--self-test-geometry") {
    exit(geometrySelfTestPassed() ? 0 : 1)
}
if arguments.contains("--self-test-mixed-dpi") {
    exit(mixedDPICompositorSelfTestPassed() ? 0 : 1)
}
if arguments.contains("--self-test-crop-transform") {
    exit(captureCropTransformSelfTestPassed() ? 0 : 1)
}
if arguments.contains("--self-test-display-read") {
    exit(displayReadSelfTestExitCode())
}
if let outputIndex = arguments.firstIndex(of: "--self-test-capture-output"), outputIndex + 1 < arguments.count {
    exit(captureOutputSelfTest(outputURL: URL(fileURLWithPath: arguments[outputIndex + 1])) ? 0 : 1)
}
if arguments.contains("--check-permission") {
    // This probe is deliberately non-prompting. The Tauri parent checks its
    // own TCC state before launching us; this catches a helper-specific grant
    // mismatch without flashing a selector or requesting consent.
    exit(CGPreflightScreenCaptureAccess() ? 0 : 3)
}

guard let outputIndex = arguments.firstIndex(of: "--output"), outputIndex + 1 < arguments.count else {
    FileHandle.standardError.write(Data("ShotEyeSelector requires --output <path>\n".utf8))
    exit(64)
}

private let delegate = SelectorDelegate(outputURL: URL(fileURLWithPath: arguments[outputIndex + 1]))
let application = NSApplication.shared
application.setActivationPolicy(.accessory)
application.delegate = delegate
application.run()
exit(Int32(delegate.exitCode))

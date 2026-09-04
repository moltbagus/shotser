import AppKit

@MainActor
final class SelectionOverlayController: NSWindowController {
    private let selectionView: SelectionView

    init(screen: NSScreen, onSelection: @escaping (CGRect) -> Void, onCancel: @escaping () -> Void) {
        selectionView = SelectionView(frame: NSRect(origin: .zero, size: screen.frame.size), onSelection: onSelection, onCancel: onCancel)
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        window.hasShadow = false
        window.contentView = selectionView
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func begin() {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(selectionView)
        NSCursor.crosshair.push()
    }

    func finish() {
        NSCursor.pop()
        window?.ignoresMouseEvents = true
        window?.orderOut(nil)
        window?.close()
    }
}

private final class SelectionView: NSView {
    private let onSelection: (CGRect) -> Void
    private let onCancel: () -> Void
    private var start: CGPoint?
    private var current: CGPoint?

    init(frame: NSRect, onSelection: @escaping (CGRect) -> Void, onCancel: @escaping () -> Void) {
        self.onSelection = onSelection
        self.onCancel = onCancel
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func mouseDown(with event: NSEvent) {
        start = convert(event.locationInWindow, from: nil)
        current = start
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer { start = nil; current = nil; needsDisplay = true }
        guard let start, let current else { return }
        let rect = CGRect(x: min(start.x, current.x), y: min(start.y, current.y), width: abs(current.x - start.x), height: abs(current.y - start.y))
        guard rect.width >= 2, rect.height >= 2 else { return }
        onSelection(rect)
    }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 53 else { return super.keyDown(with: event) }
        onCancel()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.22).setFill()
        dirtyRect.fill()
        guard let start, let current else { return }
        let rect = CGRect(x: min(start.x, current.x), y: min(start.y, current.y), width: abs(current.x - start.x), height: abs(current.y - start.y))
        NSColor.systemBlue.setStroke()
        NSBezierPath(rect: rect).stroke()
    }
}

import AppKit
import Combine
import SwiftUI

struct ShortcutBinding: Codable, Equatable {
    var keyCode: UInt16 = 19
    var modifiers: UInt = NSEvent.ModifierFlags([.command, .shift]).rawValue

    var displayName: String {
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        let prefix = (flags.contains(.command) ? "⌘" : "") + (flags.contains(.option) ? "⌥" : "") + (flags.contains(.control) ? "⌃" : "") + (flags.contains(.shift) ? "⇧" : "")
        return prefix + (keyCode == 19 ? "2" : "Key")
    }

    func matches(_ event: NSEvent) -> Bool {
        let relevant: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        return event.keyCode == keyCode && event.modifierFlags.intersection(relevant).rawValue == modifiers
    }
}

final class ShortcutManager: ObservableObject {
    @Published var binding: ShortcutBinding { didSet { save() } }
    private var monitors: [Any] = []
    private var action: (() -> Void)?

    init() {
        if let data = UserDefaults.standard.data(forKey: "areaCaptureShortcut"),
           let stored = try? JSONDecoder().decode(ShortcutBinding.self, from: data) {
            binding = stored
        } else { binding = ShortcutBinding() }
    }

    func start(action: @escaping () -> Void) {
        self.action = action
        guard monitors.isEmpty else { return }
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard let self, self.binding.matches(event) else { return }
            self.action?()
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: handler) { monitors.append(global) }
        if let local = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in handler(event); return event }) { monitors.append(local) }
    }

    func update(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        binding = ShortcutBinding(keyCode: keyCode, modifiers: modifiers.intersection([.command, .option, .control, .shift]).rawValue)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(binding) { UserDefaults.standard.set(data, forKey: "areaCaptureShortcut") }
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    @ObservedObject var manager: ShortcutManager
    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onShortcut = { keyCode, modifiers in manager.update(keyCode: keyCode, modifiers: modifiers) }
        return view
    }
    func updateNSView(_ nsView: RecorderView, context: Context) { }
}

final class RecorderView: NSView {
    var onShortcut: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); window?.makeFirstResponder(self) }
    override func keyDown(with event: NSEvent) { onShortcut?(event.keyCode, event.modifierFlags) }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill(); dirtyRect.fill()
        ("Press a shortcut…" as NSString).draw(at: CGPoint(x: 12, y: 7), withAttributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.labelColor])
    }
}

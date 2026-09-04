import ApplicationServices
import CoreGraphics
import Foundation

struct Options {
    let pid: pid_t?
    let target: String?
    let press: Bool
    let timeout: TimeInterval
    let postF18: Bool
}

func usage() -> Never {
    fputs("Usage: shoteye_ax_driver --pid PID --find NAME [--press] [--timeout SECONDS]\n       shoteye_ax_driver --post-f18\n", stderr)
    exit(2)
}

var pid: pid_t?
var target: String?
var press = false
var timeout = 4.0
var postF18 = false
var index = 1
while index < CommandLine.arguments.count {
    switch CommandLine.arguments[index] {
    case "--pid":
        index += 1
        guard index < CommandLine.arguments.count, let value = Int32(CommandLine.arguments[index]) else { usage() }
        pid = pid_t(value)
    case "--find":
        index += 1
        guard index < CommandLine.arguments.count else { usage() }
        target = CommandLine.arguments[index]
    case "--press":
        press = true
    case "--timeout":
        index += 1
        guard index < CommandLine.arguments.count, let value = Double(CommandLine.arguments[index]), value >= 0 else { usage() }
        timeout = value
    case "--post-f18":
        postF18 = true
    default:
        usage()
    }
    index += 1
}

if postF18 {
    for keyDown in [true, false] {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 79, keyDown: keyDown) else {
            fputs("KEY_POST_FAILED\n", stderr)
            exit(1)
        }
        event.flags = [.maskCommand, .maskAlternate]
        event.post(tap: .cghidEventTap)
        usleep(50_000)
    }
    print("POSTED\tshortcut=Command+Alt+F18")
    exit(0)
}

guard let resolvedPid = pid, let resolvedTarget = target, !resolvedTarget.isEmpty else { usage() }
let options = Options(pid: resolvedPid, target: resolvedTarget, press: press, timeout: timeout, postF18: postF18)
let application = AXUIElementCreateApplication(options.pid!)

func attribute(_ element: AXUIElement, _ name: CFString) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name, &value) == .success else { return nil }
    return value
}

func textAttribute(_ element: AXUIElement, _ name: CFString) -> String? {
    attribute(element, name) as? String
}

func children(of element: AXUIElement) -> [AXUIElement] {
    guard let value = attribute(element, kAXChildrenAttribute as CFString) else { return [] }
    return (value as? [AXUIElement]) ?? []
}

func normalized(_ value: String?) -> String {
    value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
}

func find(_ element: AXUIElement, named name: String) -> AXUIElement? {
    let role = textAttribute(element, kAXRoleAttribute as CFString) ?? ""
    let title = textAttribute(element, kAXTitleAttribute as CFString)
    let description = textAttribute(element, kAXDescriptionAttribute as CFString)
    let identifier = textAttribute(element, kAXIdentifierAttribute as CFString)
    if [title, description, identifier].contains(where: { normalized($0) == normalized(name) }) {
        print("MATCH\trole=\(role)\tname=\(name)")
        return element
    }
    for child in children(of: element) {
        if let match = find(child, named: name) { return match }
    }
    return nil
}

func waitForTarget() -> AXUIElement? {
    let deadline = Date().addingTimeInterval(options.timeout)
    repeat {
        if let match = find(application, named: options.target!) { return match }
        if Date() >= deadline { break }
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    } while true
    return nil
}

guard let match = waitForTarget() else {
    fputs("NOT_FOUND\tname=\(options.target!)\n", stderr)
    exit(1)
}

if options.press {
    _ = AXUIElementSetAttributeValue(application, kAXFrontmostAttribute as CFString, true as CFTypeRef)
    _ = AXUIElementSetAttributeValue(match, kAXFocusedAttribute as CFString, true as CFTypeRef)
    let result = AXUIElementPerformAction(match, kAXPressAction as CFString)
    guard result == .success else {
        fputs("PRESS_FAILED\tname=\(options.target!)\terror=\(result.rawValue)\n", stderr)
        exit(1)
    }
    print("PRESSED\tname=\(options.target!)")
}

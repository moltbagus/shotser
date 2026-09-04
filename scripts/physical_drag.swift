import CoreGraphics
import Foundation

let start = CGPoint(x: 420, y: 360)
let end = CGPoint(x: 920, y: 760)
let source = CGEventSource(stateID: .combinedSessionState)
func post(_ type: CGEventType, _ point: CGPoint, _ button: CGMouseButton = .left) {
    CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: button)?.post(tap: .cghidEventTap)
}
post(.mouseMoved, start)
Thread.sleep(forTimeInterval: 0.25)
post(.leftMouseDown, start)
Thread.sleep(forTimeInterval: 0.25)
for step in 1...12 {
    let t = CGFloat(step) / 12
    post(.leftMouseDragged, CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t))
    Thread.sleep(forTimeInterval: 0.025)
}
post(.leftMouseUp, end)

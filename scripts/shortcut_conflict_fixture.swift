import Carbon.HIToolbox
import Foundation

let shortcutName = "Command+Alt+F18"
let keyCode: UInt32 = 79 // F18 on the Apple virtual key map.
let modifiers: UInt32 = UInt32(cmdKey | optionKey)
let signature: OSType = 0x53485945 // "SHYE"

var hotKeyID = EventHotKeyID(signature: signature, id: 1)
var hotKeyRef: EventHotKeyRef?
let registerStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
guard registerStatus == noErr else {
    fputs("UNAVAILABLE\tshortcut=\(shortcutName)\tstatus=\(registerStatus)\n", stderr)
    exit(1)
}

print("RESERVED\tshortcut=\(shortcutName)\tpid=\(ProcessInfo.processInfo.processIdentifier)")
fflush(stdout)

func handleSignal(_ signalNumber: Int32) {
    if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
    print("RELEASED\tshortcut=\(shortcutName)")
    fflush(stdout)
    exit(0)
}
signal(SIGINT, handleSignal)
signal(SIGTERM, handleSignal)

RunLoop.current.run()

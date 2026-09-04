import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: write_clipboard_png OUTPUT.png\n", stderr)
    exit(2)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
guard let data = NSPasteboard.general.data(forType: .png) else {
    fputs("The macOS pasteboard does not contain PNG image data.\n", stderr)
    exit(1)
}

do {
    try data.write(to: output, options: .atomic)
    print("Wrote \(data.count) bytes to \(output.path)")
} catch {
    fputs("Could not write clipboard PNG: \(error)\n", stderr)
    exit(1)
}

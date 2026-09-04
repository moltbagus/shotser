import SwiftUI

struct ShortcutSettingsView: View {
    @ObservedObject var manager: ShortcutManager

    var body: some View {
        Form {
            Section("Area capture") {
                Text("Current shortcut: \(manager.binding.displayName)")
                ShortcutRecorder(manager: manager)
                    .frame(height: 32)
                Text("Click the recorder and press Command, Shift, Option, or Control with a key.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

import SwiftUI

enum EditorTool: String, CaseIterable, Identifiable {
    case select, arrow, rectangle, text, freehand, highlight, pixelate, measure
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .select: "cursorarrow"
        case .arrow: "arrow.up.right"
        case .rectangle: "rectangle"
        case .text: "textformat"
        case .freehand: "scribble"
        case .highlight: "highlighter"
        case .pixelate: "eye.slash"
        case .measure: "ruler"
        }
    }
}

struct EditorView: View {
    @ObservedObject var model: CaptureModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(EditorTool.allCases) { tool in
                    Button { model.selectedTool = tool } label: {
                        Image(systemName: tool.icon)
                            .frame(width: 28, height: 28)
                            .background(model.selectedTool == tool ? Color.accentColor.opacity(0.2) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help(tool.rawValue.capitalized)
                }
                Spacer()
                Button("OCR / QR") { model.inspectTextAndQR() }
                Button("Copy") { model.copyToClipboard() }
                Button("Save") { model.save() }
            }
            .padding(10)
            Divider()
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                if let image = model.image {
                    Image(nsImage: image).resizable().scaledToFit().padding(24)
                } else {
                    ContentUnavailableView("No capture yet", systemImage: "camera.viewfinder", description: Text("Choose a capture mode from the Shotser menubar item."))
                }
            }
            if let status = model.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }
            if !model.qrCodes.isEmpty {
                Text("QR: " + model.qrCodes.joined(separator: ", "))
                    .font(.caption)
                    .textSelection(.enabled)
                    .padding(.bottom, 6)
            }
        }
    }
}

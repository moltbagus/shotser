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
    @State private var dragStart: CGPoint?
    @State private var dragEnd: CGPoint?

    var body: some View {
        VStack(spacing: 0) {
            ShotserToolbar(model: model)
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                if let image = model.image {
                    GeometryReader { proxy in
                        ZStack {
                            Image(nsImage: image).resizable().scaledToFit().padding(24)
                            Canvas { context, size in
                                for annotation in model.annotations {
                                    draw(annotation, in: &context, size: size)
                                }
                                if let start = dragStart, let end = dragEnd {
                                    draw(Annotation(kind: model.selectedTool == .arrow ? .arrow : .rectangle, start: start, end: end), in: &context, size: size)
                                }
                            }
                            .gesture(annotationGesture(in: proxy.size))
                        }
                    }
                } else {
                    EmptyStateView()
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

    private func annotationGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard model.selectedTool == .rectangle || model.selectedTool == .arrow else { return }
                dragStart = CGPoint(x: value.startLocation.x / size.width, y: value.startLocation.y / size.height)
                dragEnd = CGPoint(x: value.location.x / size.width, y: value.location.y / size.height)
            }
            .onEnded { _ in
                guard let start = dragStart, let end = dragEnd else { return }
                model.addAnnotation(model.selectedTool == .arrow ? .arrow : .rectangle, start: start, end: end)
                dragStart = nil
                dragEnd = nil
            }
    }

    private func draw(_ annotation: Annotation, in context: inout GraphicsContext, size: CGSize) {
        let start = CGPoint(x: annotation.start.x * size.width, y: annotation.start.y * size.height)
        let end = CGPoint(x: annotation.end.x * size.width, y: annotation.end.y * size.height)
        var path = Path()
        switch annotation.kind {
        case .rectangle:
            path.addRect(CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y)))
        case .arrow:
            path.move(to: start)
            path.addLine(to: end)
            let angle = atan2(end.y - start.y, end.x - start.x)
            let length: CGFloat = 12
            let left = CGPoint(x: end.x - length * cos(angle - .pi / 6), y: end.y - length * sin(angle - .pi / 6))
            let right = CGPoint(x: end.x - length * cos(angle + .pi / 6), y: end.y - length * sin(angle + .pi / 6))
            path.move(to: left); path.addLine(to: end); path.addLine(to: right)
        }
        context.stroke(path, with: .color(.red), lineWidth: 3)
    }
}

private struct ShotserToolbar: View {
    @ObservedObject var model: CaptureModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 9) {
                Circle().fill(.red).frame(width: 14, height: 14)
                Circle().fill(.gray.opacity(0.55)).frame(width: 14, height: 14)
                Circle().fill(.green).frame(width: 14, height: 14)
            }
            .padding(.trailing, 7)

            ToolbarIconButton(icon: "doc.on.clipboard", help: "Copy", shortcut: "⌘C") { model.copyToClipboard() }
            ToolbarIconButton(icon: "square.and.arrow.down", help: "Save", shortcut: "⌘S") { model.save() }
            ToolbarIconButton(icon: "pin", help: "Pin screenshot", shortcut: nil) { model.statusMessage = "Pinning is coming next." }
            ToolbarDivider()

            ForEach(EditorTool.allCases) { tool in
                ToolbarIconButton(icon: tool.icon, help: tool.rawValue.capitalized, shortcut: nil, active: model.selectedTool == tool) {
                    model.selectedTool = tool
                    model.statusMessage = "Selected \(tool.rawValue.capitalized) tool."
                }
            }
            ToolbarIconButton(icon: "ellipsis", help: "More tools", shortcut: nil) { model.statusMessage = "More tools are coming next." }
            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Circle().fill(.black).frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text("#000000").font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("Tab to copy").font(.system(size: 10)).foregroundStyle(.white.opacity(0.55))
                }
            }
            ToolbarDivider()
            Readout(title: "Image size", value: imageSize)
            ToolbarDivider()
            Readout(title: "Zoom", value: "100%")
        }
        .padding(.horizontal, 18)
        .frame(height: 68)
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color(red: 0.13, green: 0.16, blue: 0.16), Color(red: 0.08, green: 0.10, blue: 0.10)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var imageSize: String {
        guard let image = model.image else { return "—" }
        return "\(Int(image.size.width))×\(Int(image.size.height))pt"
    }
}

private struct ToolbarIconButton: View {
    let icon: String
    let help: String
    let shortcut: String?
    var active = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 38, height: 38)
                .background(active ? Color.white.opacity(0.16) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(width: 42, height: 46)
        .help(shortcut.map { "\(help) (\($0))" } ?? help)
    }
}

private struct ToolbarDivider: View {
    var body: some View {
        Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 32)
    }
}

private struct Readout: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.system(size: 16, weight: .semibold, design: .rounded))
            Text(title).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
        }
        .frame(minWidth: 64, alignment: .leading)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder").font(.system(size: 34))
            Text("No capture yet").font(.headline)
            Text("Choose a capture mode from the Shotser menubar item.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

import AppKit

enum AnnotationRenderer {
    static func render(image: NSImage, annotations: [Annotation]) -> NSImage? {
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let width = source.width
        let height = source.height
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(source, in: bounds)
        context.setStrokeColor(NSColor.systemRed.cgColor)
        context.setLineWidth(max(3, CGFloat(width) / 500))
        for annotation in annotations {
            let start = CGPoint(x: annotation.start.x * bounds.width, y: bounds.maxY - annotation.start.y * bounds.height)
            let end = CGPoint(x: annotation.end.x * bounds.width, y: bounds.maxY - annotation.end.y * bounds.height)
            switch annotation.kind {
            case .rectangle:
                context.stroke(CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y)))
            case .arrow:
                context.move(to: start); context.addLine(to: end)
                let angle = atan2(end.y - start.y, end.x - start.x)
                let length: CGFloat = 18
                let left = CGPoint(x: end.x - length * cos(angle - .pi / 6), y: end.y - length * sin(angle - .pi / 6))
                let right = CGPoint(x: end.x - length * cos(angle + .pi / 6), y: end.y - length * sin(angle + .pi / 6))
                context.move(to: left); context.addLine(to: end); context.addLine(to: right); context.strokePath()
            }
        }
        guard let output = context.makeImage() else { return nil }
        return NSImage(cgImage: output, size: image.size)
    }
}

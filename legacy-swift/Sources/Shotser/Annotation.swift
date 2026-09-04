import AppKit

enum AnnotationKind: String, Codable {
    case rectangle, arrow
}

struct Annotation: Identifiable, Codable {
    let id: UUID
    let kind: AnnotationKind
    let start: CGPoint
    let end: CGPoint

    init(kind: AnnotationKind, start: CGPoint, end: CGPoint) {
        self.id = UUID()
        self.kind = kind
        self.start = start
        self.end = end
    }
}

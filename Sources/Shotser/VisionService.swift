import AppKit
import Vision

struct VisionResult {
    let text: String
    let qrCodes: [String]
}

struct VisionService {
    func inspect(_ image: NSImage) async throws -> VisionResult {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return VisionResult(text: "", qrCodes: [])
        }

        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true

        let barcodeRequest = VNDetectBarcodesRequest()
        try await perform([textRequest, barcodeRequest], on: cgImage)

        let text = (textRequest.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
        let qrCodes = (barcodeRequest.results ?? [])
            .compactMap(\.payloadStringValue)
        return VisionResult(text: text, qrCodes: qrCodes)
    }

    private func perform(_ requests: [VNRequest], on image: CGImage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(cgImage: image).perform(requests)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

import SwiftUI
import Vision
import CoreML
import QuartzCore

// MARK: - WasteDetector

@MainActor
class WasteDetector: ObservableObject {

    @Published private(set) var setupStatus: SetupStatus = .notStarted
    @Published private(set) var currentDetection: WasteDetectionResult? = nil
    @Published private(set) var isProcessing: Bool = false

    nonisolated(unsafe) private var visionModel: VNCoreMLModel? = nil
    nonisolated(unsafe) private var lastInferenceTimestamp: CFTimeInterval = 0
    private var pendingCategory: WasteCategory? = nil
    private var pendingCategoryHits: Int = 0
    private var missedDetectionFrames: Int = 0

    enum SetupStatus: Sendable {
        case notStarted, loading, success, failed
    }

    nonisolated private static let minInferenceInterval: CFTimeInterval = 0.20 // ~5 FPS
    nonisolated private static let minDisplayConfidence: Double = 0.58
    nonisolated private static let keepDisplayConfidence: Double = 0.50
    nonisolated private static let minConsistentHitsToDisplay: Int = 2
    nonisolated private static let clearAfterMissedFrames: Int = 3
    nonisolated private static let roi = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
}

// MARK: - WasteDetectionResult

struct WasteDetectionResult: Identifiable, Sendable {
    let id = UUID()
    let category: WasteCategory
    let confidence: Double
    let timestamp: Date

    init(category: WasteCategory, confidence: Double) {
        self.category = category
        self.confidence = confidence
        self.timestamp = .now
    }
}

// MARK: - Public API

extension WasteDetector {

    func setup() async {
        setupModel()
    }

    nonisolated func onImageReceived(buffer imageBuffer: CVImageBuffer) {
        let now = CACurrentMediaTime()
        guard now - lastInferenceTimestamp >= Self.minInferenceInterval else { return }
        lastInferenceTimestamp = now

        guard let model = visionModel else { return }
        let result = Self.runInference(model: model, buffer: imageBuffer)
        Task { @MainActor [weak self] in
            self?.handleInferenceResult(result)
        }
    }

    func confirmDetection() -> WasteDetectionResult? {
        let confirmed = currentDetection
        currentDetection = nil
        return confirmed
    }
}

// MARK: - Private

private extension WasteDetector {

    func setupModel() {
        guard setupStatus == .notStarted else { return }
        setupStatus = .loading

        let modelURL = Bundle.main.url(
            forResource: "EcoScanner",
            withExtension: "mlmodelc",
            subdirectory: "MLModel"
        ) ?? Bundle.main.url(forResource: "EcoScanner", withExtension: "mlmodelc")

        guard let url = modelURL else {
            setupStatus = .failed
            print("WasteDetector: EcoScanner.mlmodelc not found in bundle")
            return
        }

        do {
            let mlModel = try MLModel(contentsOf: url)
            let vnModel = try VNCoreMLModel(for: mlModel)
            self.visionModel = vnModel
            setupStatus = .success
            print("WasteDetector: Loaded EcoScanner model")
        } catch {
            setupStatus = .failed
            print("WasteDetector: Failed to load model: \(error)")
        }
    }

    func handleInferenceResult(_ result: WasteDetectionResult?) {
        guard let result else {
            pendingCategory = nil
            pendingCategoryHits = 0
            missedDetectionFrames += 1
            if missedDetectionFrames >= Self.clearAfterMissedFrames {
                currentDetection = nil
            }
            return
        }

        if let current = currentDetection, current.category == result.category {
            if result.confidence >= Self.keepDisplayConfidence {
                missedDetectionFrames = 0
                currentDetection = result
            } else {
                missedDetectionFrames += 1
                if missedDetectionFrames >= Self.clearAfterMissedFrames {
                    currentDetection = nil
                }
            }
            pendingCategory = nil
            pendingCategoryHits = 0
            return
        }

        guard result.confidence >= Self.minDisplayConfidence else {
            pendingCategory = nil
            pendingCategoryHits = 0
            missedDetectionFrames += 1
            if missedDetectionFrames >= Self.clearAfterMissedFrames {
                currentDetection = nil
            }
            return
        }

        missedDetectionFrames = 0

        if pendingCategory == result.category {
            pendingCategoryHits += 1
        } else {
            pendingCategory = result.category
            pendingCategoryHits = 1
        }

        if pendingCategoryHits >= Self.minConsistentHitsToDisplay {
            currentDetection = result
            pendingCategory = nil
            pendingCategoryHits = 0
        }
    }

    /// Static function — no actor isolation, runs inline wherever called.
    nonisolated static func runInference(model: VNCoreMLModel, buffer: CVImageBuffer) -> WasteDetectionResult? {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop
        request.regionOfInterest = Self.roi

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("WasteDetector inference error: \(error)")
            return nil
        }

        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first,
              topResult.confidence >= Float(Self.keepDisplayConfidence) else { return nil }

        guard let category = mapLabel(topResult.identifier) else { return nil }

        return WasteDetectionResult(
            category: category,
            confidence: Double(topResult.confidence)
        )
    }

    nonisolated static func mapLabel(_ label: String) -> WasteCategory? {
        let normalized = label
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Explicit coverage for all class labels currently present in ecoscannermodel.
        switch normalized {
        case "plastic":
            return .plastic
        case "glass", "green-glass", "brown-glass", "white-glass":
            return .glass
        case "metal":
            return .metal
        case "paper":
            return .paper
        case "cardboard":
            return .cardboard
        case "battery":
            return .electronic
        case "biological":
            return .biodegradable
        case "clothes", "shoes":
            return .textile
        case "trash":
            // Intentionally ignored: model says non-recyclable "trash".
            return nil
        default:
            break
        }

        if let direct = WasteCategory(rawValue: normalized) { return direct }

        let plasticKeywords = ["bottle", "water bottle", "plastic", "pop bottle", "soda bottle"]
        let glassKeywords = ["wine bottle", "beer bottle", "glass", "goblet", "vase"]
        let metalKeywords = ["can", "tin can", "aluminum", "metal", "steel"]
        let paperKeywords = ["paper", "envelope", "book", "newspaper"]
        let cardboardKeywords = ["carton", "cardboard", "box", "package"]
        let electronicKeywords = ["laptop", "cellphone", "phone", "mouse", "keyboard", "monitor", "battery"]
        let biodegradableKeywords = ["biological", "organic", "food", "compost"]
        let textileKeywords = ["clothes", "shoe", "shoes", "tshirt", "fabric", "textile"]

        if plasticKeywords.contains(where: { normalized.contains($0) }) { return .plastic }
        if glassKeywords.contains(where: { normalized.contains($0) }) { return .glass }
        if metalKeywords.contains(where: { normalized.contains($0) }) { return .metal }
        if paperKeywords.contains(where: { normalized.contains($0) }) { return .paper }
        if cardboardKeywords.contains(where: { normalized.contains($0) }) { return .cardboard }
        if electronicKeywords.contains(where: { normalized.contains($0) }) { return .electronic }
        if biodegradableKeywords.contains(where: { normalized.contains($0) }) { return .biodegradable }
        if textileKeywords.contains(where: { normalized.contains($0) }) { return .textile }

        return nil
    }
}

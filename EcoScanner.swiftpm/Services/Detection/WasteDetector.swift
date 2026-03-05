import SwiftUI
import Vision
import CoreML
import QuartzCore

// MARK: - WasteDetector

@MainActor
class WasteDetector: ObservableObject {

    enum SetupStatus: Sendable {
        case notStarted, loading, success, failed
    }

    @Published private(set) var setupStatus: SetupStatus = .notStarted
    @Published private(set) var currentDetection: WasteDetectionResult? = nil
    @Published private(set) var isProcessing: Bool = false

    nonisolated(unsafe) private var visionModel: VNCoreMLModel? = nil
    nonisolated(unsafe) private var lastInferenceTimestamp: CFTimeInterval = 0
    private var pendingCategory: WasteCategory? = nil
    private var pendingCategoryHits: Int = 0
    private var missedDetectionFrames: Int = 0

    nonisolated private static let minInferenceInterval: CFTimeInterval = 0.20 // ~5 FPS
    nonisolated private static let minDisplayConfidence: Double = 0.58
    nonisolated private static let keepDisplayConfidence: Double = 0.50
    nonisolated private static let minConsistentHitsToDisplay: Int = 3
    nonisolated private static let clearAfterMissedFrames: Int = 5
}

// MARK: - WasteDetectionResult

struct WasteDetectionResult: Identifiable, Sendable {
    let id = UUID()
    let category: WasteCategory
    let confidence: Double
    let rawLabel: String
    let timestamp: Date

    init(
        category: WasteCategory,
        confidence: Double,
        rawLabel: String = ""
    ) {
        self.category = category
        self.confidence = confidence
        self.rawLabel = rawLabel
        self.timestamp = .now
    }
}

private struct InferenceOutput: Sendable {
    let topResult: (category: WasteCategory, confidence: Double, rawLabel: String)?

    static func empty() -> InferenceOutput {
        InferenceOutput(topResult: nil)
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
        let output = Self.runInference(model: model, buffer: imageBuffer)
        Task { @MainActor [weak self] in
            self?.handleInferenceOutput(output)
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

    func handleInferenceOutput(_ output: InferenceOutput) {
        guard let top = output.topResult else {
            pendingCategory = nil
            pendingCategoryHits = 0
            registerMissedDetection()
            return
        }

        let result = WasteDetectionResult(
            category: top.category,
            confidence: top.confidence,
            rawLabel: top.rawLabel
        )

        // Same category already displayed — keep updating if confidence stays above threshold
        if let current = currentDetection, current.category == result.category {
            if result.confidence >= Self.keepDisplayConfidence {
                missedDetectionFrames = 0
                currentDetection = result
            } else {
                registerMissedDetection()
            }
            pendingCategory = nil
            pendingCategoryHits = 0
            return
        }

        // Need minimum confidence to consider a new category
        guard result.confidence >= Self.minDisplayConfidence else {
            pendingCategory = nil
            pendingCategoryHits = 0
            registerMissedDetection()
            return
        }

        missedDetectionFrames = 0

        // Temporal consistency: require N consecutive hits before showing
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

    func registerMissedDetection() {
        missedDetectionFrames += 1
        if missedDetectionFrames >= Self.clearAfterMissedFrames {
            currentDetection = nil
        }
    }

    /// Static function — no actor isolation, runs inline wherever called.
    nonisolated static func runInference(
        model: VNCoreMLModel,
        buffer: CVImageBuffer
    ) -> InferenceOutput {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("WasteDetector inference error: \(error)")
            return .empty()
        }

        // Image Classification produces VNClassificationObservation results
        guard let results = request.results as? [VNClassificationObservation], !results.isEmpty else {
            return .empty()
        }

        // Find the highest-confidence mapped category
        for observation in results {
            let confidence = Double(observation.confidence)
            guard let category = mapLabel(observation.identifier) else { continue }
            return InferenceOutput(
                topResult: (category: category, confidence: confidence, rawLabel: observation.identifier)
            )
        }

        return .empty()
    }

    nonisolated static func mapLabel(_ label: String) -> WasteCategory? {
        let normalized = label
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Primary mapping for classifier labels.
        switch normalized {
        case "biodegradable":
            return .biodegradable
        case "cardboard":
            return .cardboard
        case "glass":
            return .glass
        case "metal":
            return .metal
        case "paper":
            return .paper
        case "plastic":
            return .plastic
        case "electronic":
            return .electronic
        case "textile":
            return .textile

        // Backward compatibility with previous classifier labels.
        case "green-glass", "brown-glass", "white-glass":
            return .glass
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

        // Intentionally no fuzzy fallback: unsupported labels are ignored.
        return nil
    }
}

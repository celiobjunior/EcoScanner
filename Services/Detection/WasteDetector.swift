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
    @Published private(set) var debugFrame: DetectionDebugFrame? = nil

    nonisolated(unsafe) private var visionModel: VNCoreMLModel? = nil
    nonisolated(unsafe) private var lastInferenceTimestamp: CFTimeInterval = 0
    private var pendingCategory: WasteCategory? = nil
    private var pendingCategoryHits: Int = 0
    private var missedDetectionFrames: Int = 0

    nonisolated private static let minInferenceInterval: CFTimeInterval = 0.20 // ~5 FPS
    nonisolated private static let minDisplayConfidence: Double = 0.58
    nonisolated private static let keepDisplayConfidence: Double = 0.50
    nonisolated private static let candidateMinConfidence: Double = 0.35
    nonisolated private static let minCandidateArea: Double = 0.01
    nonisolated private static let areaNormalizationUpperBound: Double = 0.20
    nonisolated private static let smallBoxPenalty: Double = 0.55
    nonisolated private static let scoreConfidenceWeight: Double = 0.65
    nonisolated private static let scoreAreaWeight: Double = 0.20
    nonisolated private static let scoreCenterWeight: Double = 0.15
    nonisolated private static let minConsistentHitsToDisplay: Int = 2
    nonisolated private static let clearAfterMissedFrames: Int = 3
    nonisolated private static let focusRegion = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
    nonisolated private static let maxFocusDistance = sqrt(0.5 * 0.5 + 0.5 * 0.5)
    nonisolated private static let smoothingAlpha: CGFloat = 0.35
    nonisolated private static let smoothingIoUResetThreshold: Double = 0.15
    nonisolated private static let debugCandidateLimit: Int = 5
}

// MARK: - WasteDetectionResult

struct WasteDetectionResult: Identifiable, Sendable {
    let id = UUID()
    let category: WasteCategory
    let confidence: Double
    let rawLabel: String
    let boundingBox: CGRect
    let selectionScore: Double
    let boxArea: Double
    let boxCenterDistance: Double
    let timestamp: Date

    init(
        category: WasteCategory,
        confidence: Double,
        rawLabel: String = "",
        boundingBox: CGRect = .zero,
        selectionScore: Double = 0,
        boxArea: Double = 0,
        boxCenterDistance: Double = 1
    ) {
        self.category = category
        self.confidence = confidence
        self.rawLabel = rawLabel
        self.boundingBox = boundingBox
        self.selectionScore = selectionScore
        self.boxArea = boxArea
        self.boxCenterDistance = boxCenterDistance
        self.timestamp = .now
    }
}

struct DetectionCandidate: Identifiable, Sendable {
    let id = UUID()
    let category: WasteCategory
    let rawLabel: String
    let confidence: Double
    let boundingBox: CGRect
    let area: Double
    let centerDistance: Double
    let score: Double

    func asResult() -> WasteDetectionResult {
        WasteDetectionResult(
            category: category,
            confidence: confidence,
            rawLabel: rawLabel,
            boundingBox: boundingBox,
            selectionScore: score,
            boxArea: area,
            boxCenterDistance: centerDistance
        )
    }
}

struct DetectionDebugFrame: Sendable {
    let rawCandidates: [DetectionCandidate]
    let selectedCandidate: DetectionCandidate?
    let confidenceCandidate: DetectionCandidate?
}

private struct InferenceOutput: Sendable {
    let selectedCandidate: DetectionCandidate?
    let confidenceCandidate: DetectionCandidate?
    let rawCandidates: [DetectionCandidate]

    static func empty() -> InferenceOutput {
        InferenceOutput(
            selectedCandidate: nil,
            confidenceCandidate: nil,
            rawCandidates: []
        )
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
        debugFrame = DetectionDebugFrame(
            rawCandidates: output.rawCandidates,
            selectedCandidate: output.selectedCandidate,
            confidenceCandidate: output.confidenceCandidate
        )

        guard let selectedCandidate = output.selectedCandidate else {
            pendingCategory = nil
            pendingCategoryHits = 0
            registerMissedDetection()
            return
        }

        let result = stabilizedResult(from: selectedCandidate.asResult())

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

        guard result.confidence >= Self.minDisplayConfidence else {
            pendingCategory = nil
            pendingCategoryHits = 0
            registerMissedDetection()
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

    func registerMissedDetection() {
        missedDetectionFrames += 1
        if missedDetectionFrames >= Self.clearAfterMissedFrames {
            currentDetection = nil
        }
    }

    func stabilizedResult(from incoming: WasteDetectionResult) -> WasteDetectionResult {
        guard let current = currentDetection, current.category == incoming.category else {
            return incoming
        }

        let previousBox = current.boundingBox.standardized
        let newBox = incoming.boundingBox.standardized

        guard Self.isValidNormalizedBox(previousBox), Self.isValidNormalizedBox(newBox) else {
            return incoming
        }

        let iou = Self.intersectionOverUnion(previousBox, newBox)
        guard iou >= Self.smoothingIoUResetThreshold else {
            return incoming
        }

        let alpha = Self.smoothingAlpha
        let blended = CGRect(
            x: previousBox.minX + (newBox.minX - previousBox.minX) * alpha,
            y: previousBox.minY + (newBox.minY - previousBox.minY) * alpha,
            width: previousBox.width + (newBox.width - previousBox.width) * alpha,
            height: previousBox.height + (newBox.height - previousBox.height) * alpha
        )

        let clamped = Self.clampNormalizedRect(blended)
        let area = Double(clamped.width * clamped.height)

        return WasteDetectionResult(
            category: incoming.category,
            confidence: incoming.confidence,
            rawLabel: incoming.rawLabel,
            boundingBox: clamped,
            selectionScore: incoming.selectionScore,
            boxArea: area,
            boxCenterDistance: Self.normalizedCenterDistance(toFocusRegionFrom: clamped)
        )
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

        guard let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty else {
            return .empty()
        }

        var candidates: [DetectionCandidate] = []

        for observation in results {
            guard let topLabel = observation.labels.first else { continue }
            let confidence = Double(topLabel.confidence)
            guard confidence >= Self.candidateMinConfidence else { continue }
            guard let category = mapLabel(topLabel.identifier) else { continue }

            let box = observation.boundingBox.standardized
            guard Self.isValidNormalizedBox(box) else { continue }

            let area = Double(box.width * box.height)
            let centerDistance = Self.normalizedCenterDistance(toFocusRegionFrom: box)
            let centerPrior = max(0, 1 - centerDistance)
            let areaNormalized = Self.normalizedAreaScore(area)

            var score = (Self.scoreConfidenceWeight * confidence)
                + (Self.scoreAreaWeight * areaNormalized)
                + (Self.scoreCenterWeight * centerPrior)

            if area < Self.minCandidateArea {
                score *= Self.smallBoxPenalty
            }

            candidates.append(
                DetectionCandidate(
                    category: category,
                    rawLabel: topLabel.identifier,
                    confidence: confidence,
                    boundingBox: box,
                    area: area,
                    centerDistance: centerDistance,
                    score: score
                )
            )
        }

        guard !candidates.isEmpty else {
            return .empty()
        }

        let selectedCandidate = candidates.max { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.confidence < rhs.confidence
            }
            return lhs.score < rhs.score
        }

        let confidenceCandidate = candidates.max { lhs, rhs in
            if lhs.confidence == rhs.confidence {
                return lhs.area < rhs.area
            }
            return lhs.confidence < rhs.confidence
        }

        let rankedCandidates = Array(
            candidates
                .sorted { lhs, rhs in
                    if lhs.score == rhs.score {
                        return lhs.confidence > rhs.confidence
                    }
                    return lhs.score > rhs.score
                }
                .prefix(Self.debugCandidateLimit)
        )

        return InferenceOutput(
            selectedCandidate: selectedCandidate,
            confidenceCandidate: confidenceCandidate,
            rawCandidates: rankedCandidates
        )
    }

    nonisolated static func mapLabel(_ label: String) -> WasteCategory? {
        let normalized = label
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Primary mapping for object detector labels.
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

    nonisolated static func normalizedCenterDistance(toFocusRegionFrom boundingBox: CGRect) -> Double {
        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        let focusCenter = CGPoint(x: focusRegion.midX, y: focusRegion.midY)
        let dx = center.x - focusCenter.x
        let dy = center.y - focusCenter.y
        let distance = sqrt(dx * dx + dy * dy)
        return min(1, distance / maxFocusDistance)
    }

    nonisolated static func normalizedAreaScore(_ area: Double) -> Double {
        guard areaNormalizationUpperBound > 0 else { return 0 }
        return min(1, max(0, area / areaNormalizationUpperBound))
    }

    nonisolated static func isValidNormalizedBox(_ boundingBox: CGRect) -> Bool {
        guard boundingBox.width > 0, boundingBox.height > 0 else { return false }
        guard boundingBox.minX < 1, boundingBox.minY < 1 else { return false }
        guard boundingBox.maxX > 0, boundingBox.maxY > 0 else { return false }
        return true
    }

    nonisolated static func clampNormalizedRect(_ rect: CGRect) -> CGRect {
        let x = min(max(rect.minX, 0), 1)
        let y = min(max(rect.minY, 0), 1)
        let maxX = min(max(rect.maxX, 0), 1)
        let maxY = min(max(rect.maxY, 0), 1)
        return CGRect(
            x: x,
            y: y,
            width: max(0, maxX - x),
            height: max(0, maxY - y)
        )
    }

    nonisolated static func intersectionOverUnion(_ lhs: CGRect, _ rhs: CGRect) -> Double {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        let intersectionArea = Double(intersection.width * intersection.height)
        let lhsArea = Double(lhs.width * lhs.height)
        let rhsArea = Double(rhs.width * rhs.height)
        let unionArea = lhsArea + rhsArea - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }
}

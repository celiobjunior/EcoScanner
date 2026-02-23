import SwiftUI
import AVFoundation
import UIKit
import Combine

// MARK: - ScannerAVCaptureView

struct ScannerAVCaptureView: UIViewRepresentable {

    @EnvironmentObject private var cameraManager: CameraManager
    @EnvironmentObject private var wasteDetector: WasteDetector
    var debugBoundingBoxEnabled: Bool

    func makeUIView(context: Context) -> UIView {
        context.coordinator.makeUIView(with: cameraManager.captureSession)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateFrame(with: uiView.frame.size)
        context.coordinator.setDebugEnabled(debugBoundingBoxEnabled)
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(
            wasteDetector: wasteDetector,
            cameraManager: cameraManager
        )
        cameraManager.captureOutput.setSampleBufferDelegate(coordinator, queue: coordinator.queue)
        return coordinator
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        _ = uiView
        _ = coordinator
    }
}

// MARK: - Coordinator

extension ScannerAVCaptureView {

    @MainActor
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

        let wasteDetector: WasteDetector
        let cameraManager: CameraManager
        let queue = DispatchQueue(label: "ScannerAVCapture", autoreleaseFrequency: .workItem)

        private var capturePreview: AVCaptureVideoPreviewLayer? = nil
        private var selectedDebugBoxLayer: CAShapeLayer? = nil
        private var rotationCoordinator: AVCaptureDevice.RotationCoordinator? = nil
        private var rotationCoordinatorDeviceID: String? = nil
        private var lastPreviewRotationAngle: CGFloat? = nil
        private var lastCaptureRotationAngle: CGFloat? = nil
        private var latestDebugFrame: DetectionDebugFrame? = nil
        private var latestFallbackDetection: WasteDetectionResult? = nil
        private var isDebugEnabled = false
        private var subscriptions = Set<AnyCancellable>()
        private var hasBoundDetector = false
        private var hasBoundOrientationEvents = false
        private var didStartOrientationNotifications = false

        init(wasteDetector: WasteDetector, cameraManager: CameraManager) {
            self.wasteDetector = wasteDetector
            self.cameraManager = cameraManager
        }

        deinit {
            let shouldStopOrientationNotifications = didStartOrientationNotifications
            guard shouldStopOrientationNotifications else { return }
            Task { @MainActor in
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
        }

        nonisolated func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            wasteDetector.onImageReceived(buffer: imageBuffer)
        }

        func makeUIView(with session: AVCaptureSession) -> UIView {
            let uiView = UIView()
            let capturePreview = AVCaptureVideoPreviewLayer(session: session)
            capturePreview.videoGravity = .resizeAspectFill
            uiView.layer.addSublayer(capturePreview)

            let selectedLayer = CAShapeLayer()
            selectedLayer.fillColor = UIColor.clear.cgColor
            selectedLayer.lineWidth = .lineWidth.debugBox
            selectedLayer.lineDashPattern = nil
            selectedLayer.shadowColor = UIColor.black.cgColor
            selectedLayer.shadowOpacity = Float(Double.opacity.overlayStrong)
            selectedLayer.shadowRadius = .shadow.smallRadius
            selectedLayer.shadowOffset = .zero
            selectedLayer.isHidden = true
            uiView.layer.addSublayer(selectedLayer)

            self.capturePreview = capturePreview
            self.selectedDebugBoxLayer = selectedLayer
            bindDetectorIfNeeded()
            bindOrientationUpdatesIfNeeded()
            resetRotationState()
            applyOrientation()
            refreshDebugOverlay()
            return uiView
        }

        func updateFrame(with size: CGSize) {
            capturePreview?.frame = CGRect(origin: .zero, size: size)
            selectedDebugBoxLayer?.frame = CGRect(origin: .zero, size: size)
            applyOrientation()
            refreshDebugOverlay()
        }

        func setDebugEnabled(_ enabled: Bool) {
            guard isDebugEnabled != enabled else { return }
            isDebugEnabled = enabled
            refreshDebugOverlay()
        }

        func applyOrientation() {
            guard let coordinator = ensureRotationCoordinator() else { return }

            if let previewConnection = capturePreview?.connection {
                applyRotationAngle(
                    coordinator.videoRotationAngleForHorizonLevelPreview,
                    to: previewConnection,
                    cache: &lastPreviewRotationAngle
                )
                if previewConnection.isVideoMirroringSupported {
                    previewConnection.automaticallyAdjustsVideoMirroring = false
                    previewConnection.isVideoMirrored = (cameraManager.currentCamera == .front)
                }
            }

            if let outputConnection = cameraManager.captureOutput.connection(with: .video) {
                applyRotationAngle(
                    coordinator.videoRotationAngleForHorizonLevelCapture,
                    to: outputConnection,
                    cache: &lastCaptureRotationAngle
                )
            }
        }

        func bindOrientationUpdatesIfNeeded() {
            guard !hasBoundOrientationEvents else { return }
            hasBoundOrientationEvents = true

            if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                didStartOrientationNotifications = true
            }

            NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
                .sink { [weak self] _ in
                    self?.applyOrientation()
                }
                .store(in: &subscriptions)

            cameraManager.$currentCamera
                .sink { [weak self] _ in
                    self?.resetRotationState()
                    self?.applyOrientation()
                }
                .store(in: &subscriptions)
        }

        func activeVideoDevice() -> AVCaptureDevice? {
            if let connection = cameraManager.captureOutput.connection(with: .video) {
                if let device = connection.inputPorts
                    .compactMap({ ($0.input as? AVCaptureDeviceInput)?.device })
                    .first {
                    return device
                }
            }

            return cameraManager.captureSession.inputs
                .compactMap { $0 as? AVCaptureDeviceInput }
                .first?
                .device
        }

        func ensureRotationCoordinator() -> AVCaptureDevice.RotationCoordinator? {
            guard let previewLayer = capturePreview else { return nil }
            guard let device = activeVideoDevice() else {
                resetRotationState()
                return nil
            }

            if let rotationCoordinator,
               rotationCoordinatorDeviceID == device.uniqueID {
                return rotationCoordinator
            }

            let coordinator = AVCaptureDevice.RotationCoordinator(
                device: device,
                previewLayer: previewLayer
            )
            rotationCoordinator = coordinator
            rotationCoordinatorDeviceID = device.uniqueID
            lastPreviewRotationAngle = nil
            lastCaptureRotationAngle = nil
            return coordinator
        }

        func applyRotationAngle(
            _ angle: CGFloat,
            to connection: AVCaptureConnection,
            cache: inout CGFloat?
        ) {
            let normalizedAngle = normalizeRotationAngle(angle)

            if let cachedAngle = cache,
               normalizedAngleDifference(cachedAngle, normalizedAngle) < .threshold.rotationAngle {
                return
            }

            guard connection.isVideoRotationAngleSupported(normalizedAngle) else { return }
            connection.videoRotationAngle = normalizedAngle
            cache = normalizedAngle
        }

        func normalizeRotationAngle(_ angle: CGFloat) -> CGFloat {
            let normalized = angle.truncatingRemainder(dividingBy: .rotation.fullCircle)
            return normalized >= 0 ? normalized : normalized + .rotation.fullCircle
        }

        func normalizedAngleDifference(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
            let absoluteDifference = abs(lhs - rhs)
            return min(absoluteDifference, .rotation.fullCircle - absoluteDifference)
        }

        func resetRotationState() {
            rotationCoordinator = nil
            rotationCoordinatorDeviceID = nil
            lastPreviewRotationAngle = nil
            lastCaptureRotationAngle = nil
        }

        func bindDetectorIfNeeded() {
            guard !hasBoundDetector else { return }
            hasBoundDetector = true

            wasteDetector.$debugFrame
                .sink { [weak self] frame in
                    self?.latestDebugFrame = frame
                    self?.refreshDebugOverlay()
                }
                .store(in: &subscriptions)

            wasteDetector.$currentDetection
                .sink { [weak self] detection in
                    self?.latestFallbackDetection = detection
                    self?.refreshDebugOverlay()
                }
                .store(in: &subscriptions)
        }

        func refreshDebugOverlay() {
            updateDebugOverlay(
                with: latestDebugFrame,
                fallbackDetection: latestFallbackDetection,
                enabled: isDebugEnabled
            )
        }

        func updateDebugOverlay(
            with debugFrame: DetectionDebugFrame?,
            fallbackDetection: WasteDetectionResult?,
            enabled: Bool
        ) {
            guard let preview = capturePreview,
                  let selectedLayer = selectedDebugBoxLayer else { return }

            guard enabled else {
                selectedLayer.isHidden = true
                return
            }

            let selectedCandidate = debugFrame?.selectedCandidate

            let selectedBox = selectedCandidate?.boundingBox ?? fallbackDetection?.boundingBox
            let selectedColor = UIColor(
                selectedCandidate?.category.color ?? fallbackDetection?.category.color ?? .ecoLight
            ).withAlphaComponent(Double.opacity.almostOpaque)

            render(
                layer: selectedLayer,
                box: selectedBox,
                color: selectedColor,
                in: preview
            )
        }

        func render(
            layer: CAShapeLayer,
            box: CGRect?,
            color: UIColor,
            in preview: AVCaptureVideoPreviewLayer
        ) {
            guard let box, let layerRect = layerRect(from: box, in: preview) else {
                layer.isHidden = true
                return
            }

            layer.strokeColor = color.cgColor
            layer.path = UIBezierPath(roundedRect: layerRect, cornerRadius: .borderRadius.small).cgPath
            layer.isHidden = false
        }

        func layerRect(from visionBoundingBox: CGRect, in preview: AVCaptureVideoPreviewLayer) -> CGRect? {
            let box = visionBoundingBox.standardized
            guard box.width > 0, box.height > 0 else { return nil }

            // Vision output is normalized with origin in bottom-left.
            // Metadata rect expects normalized top-left origin.
            let metadataRect = CGRect(
                x: box.minX,
                y: 1 - box.maxY,
                width: box.width,
                height: box.height
            )

            var layerRect = preview.layerRectConverted(fromMetadataOutputRect: metadataRect).standardized
            if layerRect.isNull || layerRect.isEmpty || layerRect.width <= 1 || layerRect.height <= 1 {
                return nil
            }

            layerRect = layerRect.intersection(preview.bounds)
            guard !layerRect.isNull, !layerRect.isEmpty, layerRect.width > 1, layerRect.height > 1 else {
                return nil
            }

            return layerRect
        }
    }
}

private extension CGFloat {
    enum rotation {
        static let fullCircle: CGFloat = 360
    }
}

private extension CGFloat {
    enum threshold {
        static let rotationAngle: CGFloat = 0.1
    }
}

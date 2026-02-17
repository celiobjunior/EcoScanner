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

        private var uiView: UIView? = nil
        private var capturePreview: AVCaptureVideoPreviewLayer? = nil
        private var selectedDebugBoxLayer: CAShapeLayer? = nil
        private var lastOrientation: AVCaptureVideoOrientation? = nil
        private var latestDebugFrame: DetectionDebugFrame? = nil
        private var latestFallbackDetection: WasteDetectionResult? = nil
        private var isDebugEnabled = false
        private var subscriptions = Set<AnyCancellable>()
        private var hasBoundDetector = false

        init(wasteDetector: WasteDetector, cameraManager: CameraManager) {
            self.wasteDetector = wasteDetector
            self.cameraManager = cameraManager
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

            self.uiView = uiView
            self.capturePreview = capturePreview
            self.selectedDebugBoxLayer = selectedLayer
            bindDetectorIfNeeded()
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
            let orientation = currentVideoOrientation()
            if let previewConnection = capturePreview?.connection {
                if previewConnection.isVideoOrientationSupported,
                   orientation != lastOrientation {
                    previewConnection.videoOrientation = orientation
                    lastOrientation = orientation
                }
                if previewConnection.isVideoMirroringSupported {
                    previewConnection.automaticallyAdjustsVideoMirroring = false
                    previewConnection.isVideoMirrored = (cameraManager.currentCamera == .front)
                }
            }
        }

        func currentVideoOrientation() -> AVCaptureVideoOrientation {
            if let interface = uiView?.window?.windowScene?.interfaceOrientation {
                switch interface {
                case .portrait: return .portrait
                case .portraitUpsideDown: return .portraitUpsideDown
                case .landscapeLeft: return .landscapeLeft
                case .landscapeRight: return .landscapeRight
                default: break
                }
            }

            switch UIDevice.current.orientation {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            default:
                return .portrait
            }
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

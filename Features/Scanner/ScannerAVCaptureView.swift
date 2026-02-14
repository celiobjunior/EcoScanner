import SwiftUI
import AVFoundation

// MARK: - ScannerAVCaptureView

struct ScannerAVCaptureView: UIViewRepresentable {

    @EnvironmentObject private var cameraManager: CameraManager
    @EnvironmentObject private var wasteDetector: WasteDetector

    func makeUIView(context: Context) -> UIView {
        context.coordinator.makeUIView(with: cameraManager.captureSession)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateFrame(with: uiView.frame.size)
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
        private var lastOrientation: AVCaptureVideoOrientation? = nil

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
            self.uiView = uiView
            self.capturePreview = capturePreview
            applyOrientation()
            return uiView
        }

        func updateFrame(with size: CGSize) {
            capturePreview?.frame = CGRect(origin: .zero, size: size)
            applyOrientation()
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
    }
}

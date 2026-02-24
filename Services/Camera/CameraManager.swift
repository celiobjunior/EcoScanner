@preconcurrency import AVFoundation
import SwiftUI

// MARK: - CameraError

enum CameraError: Error {
    case cameraUnavailable
    case cannotAddOutput
    case deniedAuthorization
    case restrictedAuthorization
    case unknownAuthorization

    var localizedDescription: String {
        switch self {
        case .cameraUnavailable:       return "camera.error.unavailable".localized
        case .cannotAddOutput:         return "camera.error.cannot_add_output".localized
        case .deniedAuthorization:     return "camera.error.access_denied".localized
        case .restrictedAuthorization: return "camera.error.access_restricted".localized
        case .unknownAuthorization:    return "camera.error.unknown_authorization".localized
        }
    }
}

private struct CaptureSessionRef: @unchecked Sendable {
    let session: AVCaptureSession
}

// MARK: - CameraManager

@MainActor
class CameraManager: ObservableObject {

    @Published private(set) var setupStatus: SetupStatus = .notStarted
    @Published private(set) var runStatus: RunStatus = .stopped
    @Published private(set) var currentCamera: AVCaptureDevice.Position? = nil
    @Published var error: CameraError?

    let captureSession = AVCaptureSession()
    let captureOutput = AVCaptureVideoDataOutput()

    private var frontCamera: AVCaptureDeviceInput?
    private var backCamera: AVCaptureDeviceInput?

    enum SetupStatus: Sendable {
        case notStarted, loading, success, failed
        case accessDenied, accessRestricted
    }

    enum RunStatus: CaseIterable, Sendable {
        case stopped, loading, running
    }

    func setupCamera() async {
        guard setupStatus == .notStarted else { return }
        setupStatus = .loading

        let hasPermission = await checkAndRequestPermissions()
        guard hasPermission else { return }

        guard await setupCapture() else {
            setupStatus = .failed
            error = .cameraUnavailable
            return
        }
        setupStatus = .success
    }

    private let sessionQueue = DispatchQueue(label: "CameraManager.session")

    func startCapture() async {
        guard setupStatus == .success, runStatus == .stopped else { return }
        runStatus = .loading
        let sessionRef = CaptureSessionRef(session: captureSession)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                sessionRef.session.startRunning()
                continuation.resume()
            }
        }
        runStatus = .running
    }

    func stopCapture() async {
        guard setupStatus == .success, runStatus == .running else { return }
        runStatus = .loading
        let sessionRef = CaptureSessionRef(session: captureSession)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                sessionRef.session.stopRunning()
                continuation.resume()
            }
        }
        runStatus = .stopped
    }

    func switchCamera() {
        guard let frontCamera, let backCamera else { return }
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        switch currentCamera {
        case .front:
            captureSession.removeInput(frontCamera)
            if captureSession.canAddInput(backCamera) {
                captureSession.addInput(backCamera)
                currentCamera = .back
            }
        case .back:
            captureSession.removeInput(backCamera)
            if captureSession.canAddInput(frontCamera) {
                captureSession.addInput(frontCamera)
                currentCamera = .front
            }
        default: break
        }
        if let connection = captureOutput.connection(with: .video),
           connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = (currentCamera == .front)
        }
    }
}

// MARK: - Private

private extension CameraManager {

    func checkAndRequestPermissions() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted { setupStatus = .accessDenied; error = .deniedAuthorization }
            return granted
        case .restricted:
            setupStatus = .accessRestricted; error = .restrictedAuthorization; return false
        case .denied:
            setupStatus = .accessDenied; error = .deniedAuthorization; return false
        @unknown default:
            setupStatus = .failed; error = .unknownAuthorization; return false
        }
    }

    func setupCapture() async -> Bool {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .high
        guard setupInputs() else { return false }

        guard captureSession.canAddOutput(captureOutput) else {
            error = .cannotAddOutput; return false
        }

        captureOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(captureOutput)

        if let connection = captureOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = (currentCamera == .front)
            }
        }
        return true
    }

    func setupInputs() -> Bool {
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = try? AVCaptureDeviceInput(device: camera)
        }
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = try? AVCaptureDeviceInput(device: camera)
        }

        switch (frontCamera, backCamera) {
        case (.some, .some(let back)):
            currentCamera = .back; captureSession.addInput(back); return true
        case (.some(let front), .none):
            currentCamera = .front; captureSession.addInput(front); return true
        case (.none, .some(let back)):
            currentCamera = .back; captureSession.addInput(back); return true
        case (.none, .none):
            return false
        }
    }
}

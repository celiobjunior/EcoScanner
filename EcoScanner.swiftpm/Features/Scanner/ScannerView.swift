import SwiftUI

// MARK: - ScannerView

struct ScannerView: View {

    let isGuidedMode: Bool
    let onGuidedScanCompleted: (() -> Void)?

    @EnvironmentObject private var cameraManager: CameraManager
    @EnvironmentObject private var wasteDetector: WasteDetector
    @EnvironmentObject private var profileManager: UserProfileManager
    @AppStorage("scanner.autoCaptureEnabled") private var autoCaptureEnabled = true

    @State private var showFeedback = false
    @State private var lastEntry: CollectionEntry?
    @State private var lastDetection: WasteDetectionResult?
    @State private var lastFact: MaterialFact?
    @State private var scanPulse = false
    @State private var notifications: [ScannerBanner] = []
    @State private var shouldCompleteGuidedFlowAfterFeedback = false
    @State private var hasCompletedGuidedFlow = false
    @State private var isScannerVisible = false
    @State private var autoCaptureProgress: Double = 0
    @State private var autoCaptureTimer: Timer? = nil
    @State private var autoCaptureCategory: WasteCategory? = nil
    @State private var autoCaptureUserCancelled = false

    private static let autoCaptureDelay: Double = 3.0
    private static let autoCaptureTickInterval: Double = 0.05

    init(
        isGuidedMode: Bool = false,
        onGuidedScanCompleted: (() -> Void)? = nil
    ) {
        self.isGuidedMode = isGuidedMode
        self.onGuidedScanCompleted = onGuidedScanCompleted
    }

    var body: some View {
        ZStack {
            ScannerAVCaptureView()
                .ignoresSafeArea()

            VStack {
                topBar

                if isGuidedMode {
                    guidedModeCard
                        .padding(.horizontal, .spacing.x6)
                        .padding(.top, .spacing.x2)
                }

                Spacer()
                scannerGuide
                Spacer()

                if let detection = wasteDetector.currentDetection {
                    detectionLabel(for: detection)
                } else {
                    scanHint
                }

                if autoCaptureProgress > 0 {
                    autoCaptureCountdown
                }

                scanButton
                    .padding(.bottom, .spacing.x12)
            }

            if showFeedback,
               let detection = lastDetection,
               let entry = lastEntry,
               let fact = lastFact {
                FeedbackView(
                    detection: detection,
                    entry: entry,
                    profile: profileManager.profile,
                    fact: fact,
                    streak: profileManager.profile.currentStreak,
                    onDismiss: handleFeedbackDismiss,
                    onDiscard: handleFeedbackDiscard
                )
                .transition(.opacity)
            }

            bannerStack
        }
        .task {
            await cameraManager.setupCamera()
            await wasteDetector.setup()
            await cameraManager.startCapture()
        }
        .onAppear {
            isScannerVisible = true
        }
        .onDisappear {
            isScannerVisible = false
            cancelAutoCapture()
            Task { await cameraManager.stopCapture() }
        }
        .onChange(of: wasteDetector.currentDetection != nil) { _, hasDetection in
            scanPulse = hasDetection
            if hasDetection {
                startAutoCaptureIfNeeded()
            } else {
                cancelAutoCapture()
                autoCaptureUserCancelled = false
            }
        }
        .onChange(of: wasteDetector.currentDetection?.category) { _, newCategory in
            if let newCategory, newCategory != autoCaptureCategory {
                autoCaptureUserCancelled = false
                restartAutoCapture(for: newCategory)
            }
        }
        .onChange(of: cameraManager.runStatus) { _, status in
            guard isScannerVisible else { return }
            guard status == .stopped else { return }
            guard cameraManager.setupStatus == .success else { return }
            Task { await cameraManager.startCapture() }
        }
    }
}

// MARK: - Subviews

private extension ScannerView {

    var guidedModeCard: some View {
        VStack(alignment: .leading, spacing: .spacing.base) {
            HStack(spacing: .spacing.base) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoLight)

                Text("guided.scan.title".localized)
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoSmoke)
            }

            Text("guided.scan.body".localized)
                .font(.system(size: .fontSize.xsmall))
                .foregroundColor(.ecoSmoke.opacity(Double.opacity.textEmphasis))
                .lineSpacing(.lineSpacing.compact)
        }
        .frame(maxWidth: .maxWidth.guidedCard, alignment: .leading)
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                .fill(Color.black.opacity(Double.opacity.cardOverlay))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }

    var bannerStack: some View {
        VStack(spacing: .spacing.x2) {
            ForEach(notifications) { banner in
                HStack(spacing: .spacing.x2) {
                    Image(systemName: banner.icon)
                        .foregroundColor(banner.color)
                    VStack(alignment: .leading, spacing: .spacing.hairline) {
                        Text(banner.title)
                            .font(.system(size: .fontSize.xsmall, weight: .bold))
                            .foregroundColor(.ecoSmoke)
                        Text(banner.message)
                            .font(.system(size: .fontSize.caption))
                            .foregroundColor(.ecoSmoke.opacity(Double.opacity.textStrong))
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, .spacing.x4)
                .padding(.vertical, .spacing.x3)
                .frame(maxWidth: .maxWidth.scannerBanner)
                .background(
                    RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                        .fill(Color.black.opacity(Double.opacity.textSecondary))
                        .overlay(
                            RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                                .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                        )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.horizontal, .spacing.x6)
        .padding(.top, .spacing.x12)
        .allowsHitTesting(false)
    }

    var topBar: some View {
        HStack {
            statusInfoContainer
            Spacer()
            if profileManager.profile.currentStreak > 0 {
                streakCapsule
            }
        }
        .padding(.horizontal, .spacing.x6)
    }

    var statusInfoContainer: some View {
        GlassEffectContainer(spacing: .spacing.x2) {
            levelCapsule
        }
    }

    var levelCapsule: some View {
        HStack(spacing: .spacing.x2) {
            Image(systemName: profileManager.profile.currentLevel.systemImage)
                .font(.system(size: .fontSize.medium))
                .foregroundColor(.ecoLight)

            VStack(alignment: .leading, spacing: .spacing.none) {
                Text(profileManager.profile.currentLevel.displayName)
                    .font(.system(size: .fontSize.xsmall, weight: .bold))
                    .foregroundColor(.white)

                Text("common.xp_total".localized(with: profileManager.profile.totalXP))
                    .font(.system(size: .fontSize.tiny))
                    .foregroundColor(.white.opacity(Double.opacity.textSecondary))
            }
        }
        .padding(.horizontal, .spacing.x4)
        .padding(.vertical, .spacing.x2)
        .scannerCapsuleClearInteractiveGlass()
    }

    var streakCapsule: some View {
        HStack(spacing: .spacing.base) {
            Image(systemName: "flame.fill")
                .font(.system(size: .fontSize.small))
                .foregroundColor(.streakOrange)
            Text("\(profileManager.profile.currentStreak)")
                .font(.system(size: .fontSize.xsmall, weight: .bold))
                .foregroundColor(.streakOrange)
        }
        .padding(.horizontal, .spacing.x3)
        .padding(.vertical, .spacing.x2)
        .scannerCapsuleClearInteractiveGlass()
    }

    var scannerGuide: some View {
        ScannerGuideView(isActive: wasteDetector.currentDetection != nil)
            .frame(width: .size.scannerGuideFrame, height: .size.scannerGuideFrame)
            .padding(.horizontal, .spacing.x6)
            .allowsHitTesting(false)
    }

    func detectionLabel(for detection: WasteDetectionResult) -> some View {
        HStack(spacing: .spacing.x3) {
            Image(systemName: detection.category.systemImage)
                .font(.system(size: .iconSize.large))
                .foregroundColor(detection.category.color)

            VStack(alignment: .leading, spacing: .spacing.micro) {
                Text(detection.category.displayName)
                    .font(.system(size: .fontSize.large, weight: .bold))
                    .foregroundColor(detection.category.color)

                Text("scanner.confidence".localized(with: Int(detection.confidence * 100)))
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, .spacing.x6)
        .padding(.vertical, .spacing.x4)
        .scannerCapsuleClearInteractiveGlass()
        .padding(.bottom, .spacing.x6)
    }

    var scanHint: some View {
        HStack(spacing: .spacing.x2) {
            Image(systemName: "viewfinder")
                .font(.system(size: .fontSize.small))
            Text("scanner.hint".localized)
                .font(.system(size: .fontSize.small))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, .spacing.x6)
        .padding(.vertical, .spacing.x3)
        .scannerCapsuleClearInteractiveGlass()
        .padding(.bottom, .spacing.x6)
    }

    var autoCaptureCountdown: some View {
        Button {
            cancelAutoCaptureByUser()
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            HStack(spacing: .spacing.x3) {
                ProgressView(value: autoCaptureProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .ecoPrimary))

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: .iconSize.large))
                    .foregroundColor(.primary.opacity(Double.opacity.textSecondary))
            }
            .padding(.horizontal, .spacing.x5)
            .padding(.vertical, .spacing.x3)
            .frame(maxWidth: 240)
            .scannerCapsuleClearInteractiveGlass()
        }
        .buttonStyle(.plain)
        .padding(.bottom, .spacing.x3)
    }

    var scanButton: some View {
        let hasDetection = wasteDetector.currentDetection != nil
        return Button {
            performScan()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(
                        hasDetection
                        ? LinearGradient(
                            colors: [.ecoLight, .ecoPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.white.opacity(Double.opacity.disabled), .white.opacity(Double.opacity.overlayStrong)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: .lineWidth.strong
                    )
                    .frame(width: .size.scannerButtonOuter, height: .size.scannerButtonOuter)
                    .scaleEffect(scanPulse ? .scale.pulse : .scale.normal)
                    .animation(
                        hasDetection
                        ? .easeInOut(duration: Double.duration.scannerPulse).repeatForever(autoreverses: true)
                        : .easeOut(duration: Double.duration.quick),
                        value: scanPulse
                    )

                Circle()
                    .fill(
                        hasDetection
                        ? LinearGradient(
                            colors: [.ecoLight, .ecoPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.white.opacity(Double.opacity.overlayStrong), .white.opacity(Double.opacity.strokeSoft)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: .size.scannerButtonInner, height: .size.scannerButtonInner)

                Image(systemName: "viewfinder")
                    .font(.system(size: .iconSize.xlarge, weight: .medium))
                    .foregroundColor(.white.opacity(hasDetection ? Double.opacity.opaque : Double.opacity.iconInactive))
            }
        }
        .disabled(!hasDetection)
        .opacity(hasDetection ? Double.opacity.opaque : Double.opacity.disabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Actions

private extension ScannerView {

    func performScan() {
        cancelAutoCapture()
        guard let detection = wasteDetector.confirmDetection() else { return }

        let entry = profileManager.recordCollection(
            category: detection.category,
            confidence: detection.confidence
        )

        let fact = MaterialFact.randomFact(for: detection.category)

        lastDetection = detection
        lastEntry = entry
        lastFact = fact

        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        #endif

        withAnimation(.spring(response: Double.duration.feedback, dampingFraction: Double.damping.responsive)) {
            showFeedback = true
        }

        if isGuidedMode && !hasCompletedGuidedFlow {
            shouldCompleteGuidedFlowAfterFeedback = true
        }

        presentNotifications()
    }

    func handleFeedbackDismiss() {
        showFeedback = false

        guard shouldCompleteGuidedFlowAfterFeedback else { return }
        shouldCompleteGuidedFlowAfterFeedback = false

        guard !hasCompletedGuidedFlow else { return }
        hasCompletedGuidedFlow = true
        onGuidedScanCompleted?()
    }

    func handleFeedbackDiscard() {
        if let entry = lastEntry {
            profileManager.undoCollection(entry)
        }
        showFeedback = false
        lastDetection = nil
        lastEntry = nil
        lastFact = nil
    }

    func presentNotifications() {
        if let newLevel = profileManager.consumeLevelUp() {
            enqueueBanner(
                title: "notification.level_up.title".localized,
                message: "notification.level_up.body".localized(with: newLevel.displayName),
                icon: "arrow.up.circle.fill",
                color: .ecoPrimary
            )
        }

        for achievement in profileManager.consumeUnlockedAchievements() {
            enqueueBanner(
                title: "notification.achievement.title".localized,
                message: achievement.title,
                icon: achievement.systemImage,
                color: .ecoLight
            )
        }
    }

    func enqueueBanner(title: String, message: String, icon: String, color: Color) {
        let banner = ScannerBanner(title: title, message: message, icon: icon, color: color)
        withAnimation(.spring(response: Double.duration.medium, dampingFraction: Double.damping.snappy)) {
            notifications.append(banner)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double.duration.notificationLifetime) {
            withAnimation(.easeInOut(duration: Double.duration.fast)) {
                notifications.removeAll { $0.id == banner.id }
            }
        }
    }

    // MARK: - Auto-capture

    func startAutoCaptureIfNeeded() {
        guard autoCaptureEnabled else { return }
        guard !autoCaptureUserCancelled else { return }
        guard autoCaptureTimer == nil, !showFeedback else { return }
        guard let category = wasteDetector.currentDetection?.category else { return }
        autoCaptureCategory = category
        autoCaptureProgress = 0

        let timer = Timer.scheduledTimer(withTimeInterval: Self.autoCaptureTickInterval, repeats: true) { [self] _ in
            Task { @MainActor in
                guard self.autoCaptureTimer != nil else { return }
                self.autoCaptureProgress += Self.autoCaptureTickInterval / Self.autoCaptureDelay
                if self.autoCaptureProgress >= 1.0 {
                    self.cancelAutoCapture()
                    self.performScan()
                }
            }
        }
        autoCaptureTimer = timer
    }

    func cancelAutoCapture() {
        autoCaptureTimer?.invalidate()
        autoCaptureTimer = nil
        autoCaptureProgress = 0
        autoCaptureCategory = nil
    }

    func cancelAutoCaptureByUser() {
        autoCaptureUserCancelled = true
        cancelAutoCapture()
    }

    func restartAutoCapture(for category: WasteCategory) {
        cancelAutoCapture()
        autoCaptureCategory = category
        startAutoCaptureIfNeeded()
    }

}

private extension View {
    func scannerCapsuleRegularGlass() -> some View {
        self.glassEffect(.regular, in: .capsule(style: .continuous))
    }

    func scannerCapsuleClearInteractiveGlass() -> some View {
        self.glassEffect(.regular.interactive(), in: .capsule(style: .continuous))
    }
}

private struct ScannerBanner: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let color: Color
}

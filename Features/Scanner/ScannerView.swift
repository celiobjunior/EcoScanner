import SwiftUI

// MARK: - ScannerView

struct ScannerView: View {

    @EnvironmentObject private var cameraManager: CameraManager
    @EnvironmentObject private var wasteDetector: WasteDetector
    @EnvironmentObject private var profileManager: UserProfileManager

    @State private var showFeedback = false
    @State private var lastEntry: CollectionEntry?
    @State private var lastDetection: WasteDetectionResult?
    @State private var lastFact: MaterialFact?
    @State private var scanPulse = false
    @State private var notifications: [ScannerBanner] = []

    var body: some View {
        ZStack {
            ScannerAVCaptureView()
                .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                scannerGuide
                Spacer()

                if let detection = wasteDetector.currentDetection {
                    detectionLabel(for: detection)
                } else {
                    scanHint
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
                    onDismiss: { showFeedback = false }
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
        .onDisappear {
            Task { await cameraManager.stopCapture() }
        }
        .onChange(of: wasteDetector.currentDetection != nil) { _, hasDetection in
            scanPulse = hasDetection
        }
    }
}

// MARK: - Subviews

private extension ScannerView {

    var bannerStack: some View {
        VStack(spacing: .spacing.x2) {
            ForEach(notifications) { banner in
                HStack(spacing: .spacing.x2) {
                    Image(systemName: banner.icon)
                        .foregroundColor(banner.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(banner.title)
                            .font(.system(size: .fontSize.xsmall, weight: .bold))
                            .foregroundColor(.ecoSmoke)
                        Text(banner.message)
                            .font(.system(size: 11))
                            .foregroundColor(.ecoSmoke.opacity(0.82))
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, .spacing.x4)
                .padding(.vertical, .spacing.x3)
                .frame(maxWidth: 420)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.78))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.surfaceStroke, lineWidth: 1)
                        )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.horizontal, .spacing.x6)
        .padding(.top, .spacing.x12)
    }

    var topBar: some View {
        HStack {
            HStack(spacing: .spacing.x2) {
                Image(systemName: profileManager.profile.currentLevel.systemImage)
                    .font(.system(size: .fontSize.medium))
                    .foregroundColor(.ecoLight)

                VStack(alignment: .leading, spacing: 0) {
                    Text(profileManager.profile.currentLevel.displayName)
                        .font(.system(size: .fontSize.xsmall, weight: .bold))
                        .foregroundColor(.white)

                    Text("common.xp_total".localized(with: profileManager.profile.totalXP))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.78))
                }
            }
            .padding(.horizontal, .spacing.x4)
            .padding(.vertical, .spacing.x2)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().stroke(Color.surfaceStroke, lineWidth: 0.8))

            Spacer()

            if profileManager.profile.currentStreak > 0 {
                HStack(spacing: .spacing.base) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.streakOrange)
                    Text("\(profileManager.profile.currentStreak)")
                        .font(.system(size: .fontSize.xsmall, weight: .bold))
                        .foregroundColor(.streakOrange)
                }
                .padding(.horizontal, .spacing.x3)
                .padding(.vertical, .spacing.x2)
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(Capsule().stroke(Color.surfaceStroke, lineWidth: 0.8))
            }
        }
        .padding(.horizontal, .spacing.x6)
        .padding(.top, .spacing.x4)
    }

    var scannerGuide: some View {
        ScannerGuideView(isActive: wasteDetector.currentDetection != nil)
            .frame(width: 248, height: 248)
            .padding(.horizontal, .spacing.x6)
            .allowsHitTesting(false)
    }

    func detectionLabel(for detection: WasteDetectionResult) -> some View {
        HStack(spacing: .spacing.x3) {
            Image(systemName: detection.category.systemImage)
                .font(.system(size: 24))
                .foregroundColor(detection.category.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(detection.category.displayName)
                    .font(.system(size: .fontSize.large, weight: .bold))
                    .foregroundColor(detection.category.color)

                Text("scanner.confidence".localized(with: Int(detection.confidence * 100)))
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.ecoSmoke)
            }
        }
        .padding(.horizontal, .spacing.x6)
        .padding(.vertical, .spacing.x4)
        .background(Capsule().fill(Color.black.opacity(0.72)))
        .padding(.bottom, .spacing.x6)
    }

    var scanHint: some View {
        HStack(spacing: .spacing.x2) {
            Image(systemName: "viewfinder")
                .font(.system(size: 14))
            Text("scanner.hint".localized)
                .font(.system(size: .fontSize.small))
        }
        .foregroundColor(.ecoSmoke)
        .padding(.horizontal, .spacing.x6)
        .padding(.vertical, .spacing.x3)
        .background(Capsule().fill(Color.black.opacity(0.72)))
        .padding(.bottom, .spacing.x6)
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
                            colors: [.white.opacity(0.45), .white.opacity(0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 84, height: 84)
                    .scaleEffect(scanPulse ? 1.12 : 1.0)
                    .animation(
                        hasDetection
                        ? .easeInOut(duration: 1.15).repeatForever(autoreverses: true)
                        : .easeOut(duration: 0.18),
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
                            colors: [.white.opacity(0.28), .white.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 66, height: 66)

                Image(systemName: "viewfinder")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white.opacity(hasDetection ? 1.0 : 0.65))
            }
        }
        .disabled(!hasDetection)
        .opacity(hasDetection ? 1.0 : 0.45)
        .buttonStyle(.plain)
    }
}

// MARK: - Actions

private extension ScannerView {

    func performScan() {
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

        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            showFeedback = true
        }

        presentNotifications()
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            notifications.append(banner)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                notifications.removeAll { $0.id == banner.id }
            }
        }
    }
}

private struct ScannerBanner: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let color: Color
}

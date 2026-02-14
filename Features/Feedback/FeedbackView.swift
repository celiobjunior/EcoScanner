import SwiftUI

// MARK: - FeedbackView

struct FeedbackView: View {

    let detection: WasteDetectionResult
    let entry: CollectionEntry
    let profile: UserProfile
    let fact: MaterialFact
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var xpAnimated = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            ScrollView {
                VStack(spacing: .spacing.x6) {
                    materialHeader
                    Divider().padding(.horizontal)
                    xpSection
                    Divider().padding(.horizontal)
                    carbonSection
                    Divider().padding(.horizontal)
                    factSection
                    Divider().padding(.horizontal)
                    disposalSection

                    if profile.currentStreak > 1 {
                        streakBadge
                    }

                    Button(action: onDismiss) {
                        HStack(spacing: .spacing.x2) {
                            Image(systemName: "viewfinder")
                            Text("scanner.continue".localized)
                                .font(.system(size: .fontSize.small, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacing.x4)
                        .background(
                            RoundedRectangle(cornerRadius: .borderRadius.large)
                                .fill(detection.category.color)
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, .spacing.x6)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            )
            .frame(maxWidth: 500)
            .padding(.horizontal, .spacing.x6)
            .padding(.vertical, .spacing.x10)
            .offset(y: showContent ? 0 : 600)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showContent)
        }
        .onAppear {
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6)) { xpAnimated = true }
            }
        }
    }
}

// MARK: - Subviews

private extension FeedbackView {

    var materialHeader: some View {
        HStack(spacing: .spacing.x4) {
            Image(systemName: detection.category.systemImage)
                .font(.system(size: 36))
                .foregroundColor(detection.category.color)
            VStack(alignment: .leading, spacing: .spacing.base) {
                Text("feedback.material_detected".localized)
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.textSecondary)
                Text(detection.category.displayName)
                    .font(.system(size: .fontSize.large, weight: .bold))
                    .foregroundColor(detection.category.color)
                Text("feedback.confidence_label".localized(with: Int(detection.confidence * 100)))
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.ecoLight)
        }
        .padding(.horizontal)
    }

    var xpSection: some View {
        VStack(spacing: .spacing.x3) {
            HStack {
                Image(systemName: "star.fill").foregroundColor(.xpGold)
                Text("common.xp_gain".localized(with: entry.xpEarned))
                    .font(.system(size: .fontSize.big, weight: .bold))
                    .foregroundColor(.xpGold)
                    .scaleEffect(xpAnimated ? 1.0 : 0.5)
                    .opacity(xpAnimated ? 1.0 : 0)
            }

            VStack(spacing: .spacing.base) {
                HStack {
                    HStack(spacing: .spacing.base) {
                        Image(systemName: profile.currentLevel.systemImage)
                            .foregroundColor(.ecoPrimary)
                        Text(profile.currentLevel.displayName)
                            .font(.system(size: .fontSize.xsmall, weight: .medium))
                    }
                    Spacer()
                    Text("profile.level_label".localized(with: profile.currentLevel.rawValue))
                        .font(.system(size: .fontSize.xsmall))
                        .foregroundColor(.textSecondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5)).frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.ecoLight, .ecoPrimary], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * profile.levelProgress, height: 8)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: xpAnimated)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }

    var factSection: some View {
        HStack(alignment: .top, spacing: .spacing.x3) {
            Image(systemName: fact.isPositive ? "lightbulb.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundColor(fact.isPositive ? .ecoLight : .streakOrange)

            VStack(alignment: .leading, spacing: .spacing.base) {
                Text(fact.isPositive ? "feedback.did_you_know".localized : "feedback.watch_out".localized)
                    .font(.system(size: .fontSize.xsmall, weight: .bold))
                    .foregroundColor(fact.isPositive ? .ecoLight : .streakOrange)
                Text(fact.fact)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(4)
                if let source = fact.source {
                    Text("feedback.source".localized(with: source))
                        .font(.system(size: 10)).foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }

    var carbonSection: some View {
        HStack(spacing: .spacing.x3) {
            Image(systemName: "leaf.fill").font(.system(size: 20)).foregroundColor(.ecoLight)
            VStack(alignment: .leading, spacing: 2) {
                Text("feedback.this_collection_impact".localized)
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.textSecondary)
                Text(String(format: "feedback.co2_saved_format".localized, entry.co2Saved))
                    .font(.system(size: .fontSize.medium, weight: .bold)).foregroundColor(.ecoPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("feedback.total_accumulated".localized)
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.textSecondary)
                Text(String(format: "feedback.co2_total_format".localized, profile.totalCO2Saved))
                    .font(.system(size: .fontSize.small, weight: .semibold)).foregroundColor(.ecoPrimary)
            }
        }
        .padding(.horizontal)
    }

    var disposalSection: some View {
        HStack(alignment: .top, spacing: .spacing.x3) {
            Image(systemName: "trash.circle.fill").font(.system(size: 24)).foregroundColor(detection.category.color)
            VStack(alignment: .leading, spacing: 2) {
                Text("feedback.correct_disposal".localized)
                    .font(.system(size: .fontSize.xsmall, weight: .bold)).foregroundColor(.textSecondary)
                Text(detection.category.disposalInstruction)
                    .font(.system(size: .fontSize.small)).foregroundColor(.textPrimary).lineSpacing(4)
            }
        }
        .padding(.horizontal)
    }

    var streakBadge: some View {
        HStack(spacing: .spacing.x2) {
            Image(systemName: "flame.fill").foregroundColor(.streakOrange)
            Text("feedback.streak_days".localized(with: profile.currentStreak))
                .font(.system(size: .fontSize.small, weight: .bold)).foregroundColor(.streakOrange)
        }
        .padding(.vertical, .spacing.x2)
        .padding(.horizontal, .spacing.x5)
        .background(Capsule().fill(Color.streakOrange.opacity(0.15)))
    }
}

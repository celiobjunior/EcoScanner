import SwiftUI

// MARK: - FeedbackView

struct FeedbackView: View {

    let detection: WasteDetectionResult
    let entry: CollectionEntry
    let profile: UserProfile
    let fact: MaterialFact
    let streak: Int
    let onDismiss: () -> Void
    let onDiscard: () -> Void

    @State private var showContent = false
    @State private var xpAnimated = false

    var body: some View {
        ZStack {
            Color.black.opacity(Double.opacity.scrim)
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


                    HStack(spacing: .spacing.x3) {
                        Button(action: onDiscard) {
                            HStack(spacing: .spacing.x2) {
                                Image(systemName: "trash")
                                Text("scanner.discard".localized)
                                    .font(.system(size: .fontSize.small, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, .spacing.x4)
                            .background(
                                RoundedRectangle(cornerRadius: .borderRadius.large)
                                    .fill(Color.red)
                            )
                        }

                        Button(action: onDismiss) {
                            HStack(spacing: .spacing.x2) {
                                Image(systemName: "viewfinder")
                                Text("scanner.continue".localized)
                                    .font(.system(size: .fontSize.small, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, .spacing.x4)
                            .background(
                                RoundedRectangle(cornerRadius: .borderRadius.large)
                                    .fill(detection.category.color)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, .spacing.x6)
            }
            .background(
                RoundedRectangle(cornerRadius: .borderRadius.xl)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(Double.opacity.overlaySoft),
                        radius: .shadow.largeRadius,
                        y: .shadow.largeYOffset
                    )
            )
            .frame(maxWidth: .maxWidth.feedbackCard)
            .padding(.horizontal, .spacing.x6)
            .padding(.vertical, .spacing.x10)
            .offset(y: showContent ? .spacing.none : .size.feedbackHiddenOffset)
            .animation(.spring(response: Double.duration.long, dampingFraction: Double.damping.medium), value: showContent)
        }
        .onAppear {
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.duration.long) {
                withAnimation(.spring(response: Double.duration.extraLong)) { xpAnimated = true }
            }
        }
    }
}

// MARK: - Subviews

private extension FeedbackView {

    var materialHeader: some View {
        HStack(spacing: .spacing.x4) {
            Image(systemName: detection.category.systemImage)
                .font(.system(size: .iconSize.hero))
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
            if streak > 1 {
                HStack(spacing: .spacing.x2) {
                    Image(systemName: "flame.fill").foregroundColor(.streakOrange)
                    Text("feedback.streak_days".localized(with: streak))
                        .font(.system(size: .fontSize.xsmall, weight: .bold)).foregroundColor(.streakOrange)
                }
                .padding(.vertical, .spacing.x2)
                .padding(.horizontal, .spacing.x3)
                .background(Capsule().fill(Color.streakOrange.opacity(Double.opacity.badge)))
            }
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
                    .scaleEffect(xpAnimated ? .scale.normal : .scale.hidden)
                    .opacity(xpAnimated ? Double.opacity.opaque : Double.opacity.none)
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
                        RoundedRectangle(cornerRadius: .borderRadius.xsmall)
                            .fill(Color(.systemGray5)).frame(height: .progress.thin)
                        RoundedRectangle(cornerRadius: .borderRadius.xsmall)
                            .fill(LinearGradient(colors: [.ecoLight, .ecoPrimary], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * profile.levelProgress, height: .progress.thin)
                            .animation(.easeOut(duration: Double.duration.slow).delay(Double.duration.regular), value: xpAnimated)
                    }
                }
                .frame(height: .progress.thin)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }

    var factSection: some View {
        HStack(alignment: .top, spacing: .spacing.x3) {
            Image(systemName: fact.isPositive ? "lightbulb.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: .iconSize.title))
                .foregroundColor(fact.isPositive ? .ecoPrimary : .streakOrange)

            VStack(alignment: .leading, spacing: .spacing.base) {
                Text(fact.isPositive ? "feedback.did_you_know".localized : "feedback.watch_out".localized)
                    .font(.system(size: .fontSize.xsmall, weight: .bold))
                    .foregroundColor(fact.isPositive ? .ecoPrimary : .streakOrange)
                Text(fact.fact)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(.lineSpacing.regular)
                if let source = fact.source {
                    Text("feedback.source".localized(with: source))
                        .font(.system(size: .fontSize.tiny)).foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }

    var carbonSection: some View {
        HStack(spacing: .spacing.x3) {
            Image(systemName: "leaf.fill").font(.system(size: .iconSize.medium)).foregroundColor(.ecoPrimary)
            VStack(alignment: .leading, spacing: .spacing.micro) {
                Text("feedback.this_collection_impact".localized)
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.textSecondary)
                Text(String(format: "feedback.co2_saved_format".localized, entry.co2Saved))
                    .font(.system(size: .fontSize.medium, weight: .bold)).foregroundColor(.ecoPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: .spacing.micro) {
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
            Image(systemName: "trash.circle.fill").font(.system(size: .iconSize.large)).foregroundColor(detection.category.color)
            VStack(alignment: .leading, spacing: .spacing.micro) {
                Text("feedback.correct_disposal".localized)
                    .font(.system(size: .fontSize.xsmall, weight: .bold)).foregroundColor(.textSecondary)
                Text(detection.category.disposalInstruction)
                    .font(.system(size: .fontSize.small)).foregroundColor(.textPrimary).lineSpacing(.lineSpacing.regular)
            }
        }
        .padding(.horizontal)
    }
}


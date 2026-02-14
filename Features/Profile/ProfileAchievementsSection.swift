import SwiftUI

// MARK: - Achievements

extension ProfileView {

    var achievementsSection: some View {
        VStack(alignment: .leading, spacing: .spacing.x4) {
            Text("profile.achievements_title".localized)
                .font(.system(size: .fontSize.large, weight: .bold))
                .foregroundColor(.ecoSmoke)

            let columns = [
                GridItem(
                    .adaptive(
                        minimum: achievementCardSize.width,
                        maximum: achievementCardSize.width
                    ),
                    spacing: .spacing.x3
                )
            ]
            LazyVGrid(columns: columns, spacing: .spacing.x3) {
                ForEach(Achievement.all, id: \.id) { achievement in
                    let isUnlocked = profileManager.profile.unlockedAchievementIDs.contains(achievement.id)
                    let progress = progress(for: achievement)

                    Button { selectedAchievement = achievement } label: {
                        VStack(spacing: .spacing.base) {
                            Image(systemName: achievement.systemImage)
                                .font(.system(size: 30))
                                .foregroundColor(isUnlocked ? .ecoPrimary : .achievementLocked)
                                .opacity(isUnlocked ? 1 : 0.78)

                            Text(achievement.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isUnlocked ? .ecoSmoke : .ecoSmoke.opacity(0.48))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            Text(progress.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isUnlocked ? .ecoSmoke.opacity(0.82) : .ecoSmoke.opacity(0.62))

                            progressBar(progress: progress, tint: isUnlocked ? .ecoPrimary : .achievementLocked)
                        }
                        .padding(.horizontal, .spacing.x2)
                        .frame(width: achievementCardSize.width, height: achievementCardSize.height)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isUnlocked ? Color.ecoPrimary.opacity(0.24) : Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            isUnlocked ? Color.ecoPrimary.opacity(0.55) : Color.achievementLocked.opacity(0.35),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            achievementPopover(for: achievement)
        }
    }

    func achievementPopover(for achievement: Achievement) -> some View {
        let isUnlocked = profileManager.profile.unlockedAchievementIDs.contains(achievement.id)
        let progress = progress(for: achievement)

        return ScrollView(showsIndicators: false) {
            VStack(spacing: .spacing.x5) {
                VStack(spacing: .spacing.x3) {
                    Image(systemName: achievement.systemImage)
                        .font(.system(size: 40))
                        .foregroundStyle(
                            isUnlocked
                            ? LinearGradient(colors: [.ecoLight, .ecoPrimary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.achievementLocked, .achievementLocked.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )

                    Text(achievement.title)
                        .font(.system(size: .fontSize.big, weight: .bold))
                        .foregroundColor(.ecoSmoke)
                        .multilineTextAlignment(.center)
                }

                Text(achievement.description)
                    .font(.system(size: .fontSize.small))
                    .foregroundColor(.ecoSmoke.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.spacing.x4)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.surfaceStroke, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: .spacing.x3) {
                    HStack(spacing: .spacing.x2) {
                        Image(systemName: "target")
                            .foregroundColor(.ecoPrimary)
                        Text("profile.requirement".localized)
                            .font(.system(size: .fontSize.xsmall, weight: .bold))
                            .foregroundColor(.ecoSmoke.opacity(0.78))
                    }

                    Text(achievement.requirement.summary)
                        .font(.system(size: .fontSize.medium, weight: .semibold))
                        .foregroundColor(.ecoSmoke)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .overlay(Color.surfaceStroke)

                    HStack {
                        Text("profile.progress_label".localized)
                            .font(.system(size: .fontSize.xsmall, weight: .bold))
                            .foregroundColor(.ecoSmoke.opacity(0.78))
                        Spacer()
                        Text(progress.label)
                            .font(.system(size: .fontSize.xsmall, weight: .semibold))
                            .foregroundColor(.ecoSmoke)
                    }

                    progressBar(progress: progress, tint: isUnlocked ? .ecoPrimary : .achievementLocked)
                }
                .padding(.spacing.x4)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.surfaceStroke, lineWidth: 1)
                        )
                )

                HStack(spacing: .spacing.x2) {
                    Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundColor(isUnlocked ? .ecoPrimary : .achievementLocked)
                    Text(isUnlocked ? "profile.unlocked".localized : "profile.locked".localized)
                        .font(.system(size: .fontSize.small, weight: .semibold))
                        .foregroundColor(isUnlocked ? .ecoPrimary : .achievementLocked)
                }
                .padding(.vertical, .spacing.x2)
                .padding(.horizontal, .spacing.x5)
                .background(
                    Capsule()
                        .fill((isUnlocked ? Color.ecoPrimary : Color.achievementLocked).opacity(0.16))
                        .overlay(
                            Capsule()
                                .stroke((isUnlocked ? Color.ecoPrimary : Color.achievementLocked).opacity(0.56), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, .spacing.x6)
            .padding(.top, .spacing.x6)
            .padding(.bottom, .spacing.x8)
        }
        .background(Color.ecoInk.ignoresSafeArea())
        .presentationDetents([.height(540), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.ecoInk)
    }

    private func progress(for achievement: Achievement) -> AchievementProgress {
        switch achievement.requirement {
        case .totalCollections(let target):
            return AchievementProgress(
                current: Double(profileManager.profile.totalCollections),
                target: Double(target),
                usesDecimal: false
            )
        case .categoryCollections(let category, let target):
            return AchievementProgress(
                current: Double(profileManager.collectionCount(for: category)),
                target: Double(target),
                usesDecimal: false
            )
        case .streakDays(let target):
            return AchievementProgress(
                current: Double(profileManager.profile.currentStreak),
                target: Double(target),
                usesDecimal: false
            )
        case .co2Saved(let target):
            return AchievementProgress(
                current: profileManager.profile.totalCO2Saved,
                target: target,
                usesDecimal: true
            )
        case .levelReached(let target):
            return AchievementProgress(
                current: Double(profileManager.profile.currentLevel.rawValue),
                target: Double(target),
                usesDecimal: false
            )
        }
    }

    @ViewBuilder
    private func progressBar(progress: AchievementProgress, tint: Color) -> some View {
        GeometryReader { geometry in
            let fillWidth = progress.fraction > 0 ? max(6, geometry.size.width * progress.fraction) : 0
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.14))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(tint.opacity(0.92))
                    .frame(width: fillWidth, height: 8)
            }
        }
        .frame(height: 8)
    }
}

private struct AchievementProgress {
    let current: Double
    let target: Double
    let usesDecimal: Bool

    var clampedCurrent: Double {
        max(0, min(current, target))
    }

    var fraction: Double {
        guard target > 0 else { return 1 }
        return max(0, min(clampedCurrent / target, 1))
    }

    var label: String {
        if usesDecimal {
            return "profile.progress_decimal".localized(with: clampedCurrent, target)
        }
        return "profile.progress_fraction".localized(
            with: Int(clampedCurrent.rounded(.down)),
            Int(target.rounded(.down))
        )
    }
}

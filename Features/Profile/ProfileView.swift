import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @EnvironmentObject var profileManager: UserProfileManager
    @State var selectedAchievement: Achievement? = nil
    @State private var showLevelsSheet = false
    let achievementCardSize = CGSize(width: .size.achievementCardWidth, height: .size.achievementCardHeight)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ecoInk.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: .spacing.x6) {
                        profileHeader
                        carbonFootprintCard
                        statsGrid
                        achievementsSection
                        Spacer(minLength: .spacing.x10)
                    }
                    .padding(.horizontal, .spacing.x6)
                    .padding(.top, .spacing.x4)
                    .frame(maxWidth: .maxWidth.appContent)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("profile.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.ecoInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showLevelsSheet) {
                levelsSheet
            }
        }
    }
}

// MARK: - Profile Header

private extension ProfileView {

    var profileHeader: some View {
        VStack(spacing: .spacing.x5) {
            VStack(spacing: .spacing.x3) {
                Image(systemName: profileManager.profile.currentLevel.systemImage)
                    .font(.system(size: .iconSize.display, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [.ecoLight, .ecoPrimary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text(profileManager.profile.name)
                    .font(.system(size: .fontSize.large, weight: .bold))
                    .foregroundColor(.ecoSmoke)
            }

            VStack(spacing: .spacing.x2) {
                Text(profileManager.profile.currentLevel.displayName)
                    .font(.system(size: .fontSize.medium, weight: .semibold))
                    .foregroundColor(.ecoPrimary)
                Text("profile.level_label".localized(with: profileManager.profile.currentLevel.rawValue))
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textMuted))
                Button("profile.levels_button".localized) {
                    showLevelsSheet = true
                }
                .font(.system(size: .fontSize.xsmall, weight: .semibold))
                .foregroundColor(.ecoLight)
            }

            VStack(spacing: .spacing.base) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: .borderRadius.compact).fill(Color(.systemGray5)).frame(height: .progress.regular)
                        RoundedRectangle(cornerRadius: .borderRadius.compact)
                            .fill(LinearGradient(colors: [.ecoLight, .ecoPrimary], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * profileManager.profile.levelProgress, height: .progress.regular)
                    }
                }
                .frame(height: .progress.regular)

                HStack {
                    Text("common.xp_total".localized(with: profileManager.profile.totalXP))
                        .font(.system(size: .fontSize.xsmall, weight: .medium)).foregroundColor(.xpGold)
                    Spacer()
                    if profileManager.profile.xpToNextLevel > 0 {
                        Text("profile.xp_to_next".localized(with: profileManager.profile.xpToNextLevel))
                            .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textMuted))
                    } else {
                        HStack(spacing: .spacing.base) {
                            Image(systemName: "trophy.fill").font(.system(size: .iconSize.xsmall))
                            Text("profile.max_level".localized)
                        }
                        .font(.system(size: .fontSize.xsmall)).foregroundColor(.xpGold)
                    }
                }

                if profileManager.profile.xpRequiredForCurrentStep > 0 {
                    Text(
                        "profile.level_progress".localized(
                            with: profileManager.profile.xpIntoCurrentLevel,
                            profileManager.profile.xpRequiredForCurrentStep
                        )
                    )
                    .font(.system(size: .fontSize.caption))
                    .foregroundColor(.ecoSmoke.opacity(Double.opacity.textLow))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, .spacing.x4)
        }
        .padding(.vertical, .spacing.x6)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.xlarge)
                .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.xlarge)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }

    var levelsSheet: some View {
        NavigationStack {
            ZStack {
                Color.ecoInk.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing.x4) {
                        Text("profile.levels_subtitle".localized)
                            .font(.system(size: .fontSize.small))
                            .foregroundColor(.ecoSmoke.opacity(Double.opacity.cardOverlay))
                            .padding(.horizontal, .spacing.x6)

                        ForEach(EcoLevel.allCases, id: \.rawValue) { level in
                            levelRow(level)
                        }
                    }
                    .padding(.vertical, .spacing.x4)
                }
            }
            .navigationTitle("profile.levels_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.ecoInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("help.close".localized) {
                        showLevelsSheet = false
                    }
                    .foregroundColor(.ecoLight)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.ecoInk)
    }

    func levelRow(_ level: EcoLevel) -> some View {
        let isUnlocked = profileManager.profile.totalXP >= level.minXP
        let isCurrent = profileManager.profile.currentLevel == level

        return HStack(spacing: .spacing.x4) {
            Image(systemName: level.systemImage)
                .font(.system(size: .iconSize.large))
                .foregroundColor(isUnlocked ? .ecoPrimary : .gray)
                .frame(width: .size.levelIconSlot, height: .size.levelIconSlot)

            VStack(alignment: .leading, spacing: .spacing.micro) {
                Text(level.displayName)
                    .font(.system(size: .fontSize.medium, weight: .semibold))
                    .foregroundColor(.ecoSmoke)
                Text("profile.level_label".localized(with: level.rawValue))
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.ecoSmoke.opacity(Double.opacity.textMuted))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: .spacing.micro) {
                Text("common.xp_total".localized(with: level.minXP))
                    .font(.system(size: .fontSize.xsmall, weight: .semibold))
                    .foregroundColor(.xpGold)
                Text(isCurrent ? "profile.level_current".localized : (isUnlocked ? "profile.unlocked".localized : "profile.level_locked".localized))
                    .font(.system(size: .fontSize.tiny))
                    .foregroundColor(isCurrent ? .ecoPrimary : .ecoSmoke.opacity(Double.opacity.textLow))
            }
        }
        .padding(.horizontal, .spacing.x5)
        .padding(.vertical, .spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                .fill(isCurrent ? Color.ecoPrimary.opacity(Double.opacity.overlaySoft) : Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
        .padding(.horizontal, .spacing.x6)
    }
}

// MARK: - Carbon Card + Stats

private extension ProfileView {

    var carbonFootprintCard: some View {
        HStack(spacing: .spacing.x5) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.ecoLight.opacity(Double.opacity.gradientSoft), .ecoPrimary.opacity(Double.opacity.gradientSoft)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: .size.carbonCardIcon, height: .size.carbonCardIcon)
                Image(systemName: "leaf.fill").font(.system(size: .iconSize.large)).foregroundColor(.ecoPrimary)
            }
            VStack(alignment: .leading, spacing: .spacing.base) {
                Text("profile.carbon_footprint".localized)
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textMuted))
                Text(String(format: "profile.co2_format".localized, profileManager.profile.totalCO2Saved))
                    .font(.system(size: .fontSize.big, weight: .bold)).foregroundColor(.ecoPrimary)
                Text("profile.co2_subtitle".localized)
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textMuted))
            }
            Spacer()
        }
        .padding(.spacing.x5)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.large)
                .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.large)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }

    var stats: [(String, String, String)] {
        [
            ("shippingbox.fill", "\(profileManager.profile.totalCollections)", "profile.items_collected".localized),
            ("flame.fill", "\(profileManager.profile.currentStreak)", "profile.streak_days".localized),
            ("star.fill", "\(profileManager.profile.totalXP)", "profile.total_xp".localized),
            ("medal.fill", "\(profileManager.profile.unlockedAchievementIDs.count)", "profile.achievements_label".localized),
        ]
    }

    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacing.x4) {
            ForEach(stats, id: \.2) { iconName, value, label in
                VStack(spacing: .spacing.x2) {
                    Image(systemName: iconName).font(.system(size: .iconSize.large)).foregroundColor(.ecoPrimary)
                    Text(value).font(.system(size: .fontSize.large, weight: .bold)).foregroundColor(.ecoSmoke)
                    Text(label).font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textMuted))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacing.x5)
                .background(
                    RoundedRectangle(cornerRadius: .borderRadius.large)
                        .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                        .overlay(
                            RoundedRectangle(cornerRadius: .borderRadius.large)
                                .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                        )
                )
            }
        }
    }
}

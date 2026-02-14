import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @EnvironmentObject var profileManager: UserProfileManager
    @State var selectedAchievement: Achievement? = nil
    @State private var showLevelsSheet = false
    let achievementCardSize = CGSize(width: 150, height: 136)

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
                    .frame(maxWidth: 1000)
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
                    .font(.system(size: 48, weight: .light))
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
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(0.66))
                Button("profile.levels_button".localized) {
                    showLevelsSheet = true
                }
                .font(.system(size: .fontSize.xsmall, weight: .semibold))
                .foregroundColor(.ecoLight)
            }

            VStack(spacing: .spacing.base) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)).frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [.ecoLight, .ecoPrimary], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * profileManager.profile.levelProgress, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("common.xp_total".localized(with: profileManager.profile.totalXP))
                        .font(.system(size: .fontSize.xsmall, weight: .medium)).foregroundColor(.xpGold)
                    Spacer()
                    if profileManager.profile.xpToNextLevel > 0 {
                        Text("profile.xp_to_next".localized(with: profileManager.profile.xpToNextLevel))
                            .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(0.66))
                    } else {
                        HStack(spacing: .spacing.base) {
                            Image(systemName: "trophy.fill").font(.system(size: 12))
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
                    .font(.system(size: 11))
                    .foregroundColor(.ecoSmoke.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, .spacing.x4)
        }
        .padding(.vertical, .spacing.x6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.surfaceStroke, lineWidth: 1))
        )
    }

    var levelsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing.x4) {
                    Text("profile.levels_subtitle".localized)
                        .font(.system(size: .fontSize.small))
                        .foregroundColor(.ecoSmoke.opacity(0.72))
                        .padding(.horizontal, .spacing.x6)

                    ForEach(EcoLevel.allCases, id: \.rawValue) { level in
                        levelRow(level)
                    }
                }
                .padding(.vertical, .spacing.x4)
            }
            .background(Color.ecoInk.ignoresSafeArea())
            .navigationTitle("profile.levels_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.ecoInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.ecoInk)
    }

    func levelRow(_ level: EcoLevel) -> some View {
        let isUnlocked = profileManager.profile.totalXP >= level.minXP
        let isCurrent = profileManager.profile.currentLevel == level

        return HStack(spacing: .spacing.x4) {
            Image(systemName: level.systemImage)
                .font(.system(size: 24))
                .foregroundColor(isUnlocked ? .ecoPrimary : .gray)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(level.displayName)
                    .font(.system(size: .fontSize.medium, weight: .semibold))
                    .foregroundColor(.ecoSmoke)
                Text("profile.level_label".localized(with: level.rawValue))
                    .font(.system(size: .fontSize.xsmall))
                    .foregroundColor(.ecoSmoke.opacity(0.66))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("common.xp_total".localized(with: level.minXP))
                    .font(.system(size: .fontSize.xsmall, weight: .semibold))
                    .foregroundColor(.xpGold)
                Text(isCurrent ? "profile.level_current".localized : (isUnlocked ? "profile.unlocked".localized : "profile.level_locked".localized))
                    .font(.system(size: 10))
                    .foregroundColor(isCurrent ? .ecoPrimary : .ecoSmoke.opacity(0.62))
            }
        }
        .padding(.horizontal, .spacing.x5)
        .padding(.vertical, .spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrent ? Color.ecoPrimary.opacity(0.2) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCurrent ? Color.ecoPrimary.opacity(0.56) : Color.surfaceStroke, lineWidth: 1)
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
                    .fill(LinearGradient(colors: [.ecoLight.opacity(0.3), .ecoPrimary.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "leaf.fill").font(.system(size: 24)).foregroundColor(.ecoPrimary)
            }
            VStack(alignment: .leading, spacing: .spacing.base) {
                Text("profile.carbon_footprint".localized)
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(0.66))
                Text(String(format: "profile.co2_format".localized, profileManager.profile.totalCO2Saved))
                    .font(.system(size: .fontSize.big, weight: .bold)).foregroundColor(.ecoPrimary)
                Text("profile.co2_subtitle".localized)
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(0.66))
            }
            Spacer()
        }
        .padding(.spacing.x5)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.surfaceStroke, lineWidth: 1))
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
                    Image(systemName: iconName).font(.system(size: 24)).foregroundColor(.ecoPrimary)
                    Text(value).font(.system(size: .fontSize.large, weight: .bold)).foregroundColor(.ecoSmoke)
                    Text(label).font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(0.66))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacing.x5)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.surfaceStroke, lineWidth: 1))
                )
            }
        }
    }
}

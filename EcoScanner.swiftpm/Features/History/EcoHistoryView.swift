import SwiftUI

// MARK: - EcoHistoryView

struct EcoHistoryView: View {

    @EnvironmentObject var profileManager: UserProfileManager
    @State private var selectedFilter: WasteCategory? = nil

    private var allEntries: [CollectionEntry] {
        profileManager.fetchHistory()
    }

    private var entries: [CollectionEntry] {
        if let filter = selectedFilter {
            return allEntries.filter { $0.categoryRawValue == filter.rawValue }
        }
        return allEntries
    }

    private var filterCategories: [WasteCategory] {
        let modelSupported = WasteCategory.modelSupportedCases
        let legacyUsed = allEntries.reduce(into: [WasteCategory]()) { acc, entry in
            guard let category = entry.category else { return }
            guard !modelSupported.contains(category), !acc.contains(category) else { return }
            acc.append(category)
        }
        return modelSupported + legacyUsed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ecoInk.ignoresSafeArea()

                VStack(spacing: .spacing.none) {
                    categoryFilter.padding(.vertical, .spacing.x3)

                    if entries.isEmpty {
                        emptyState
                    } else {
                        summaryHeader
                            .padding(.horizontal, .spacing.x6)
                            .padding(.bottom, .spacing.x3)
                        List(entries, id: \.id) { entry in
                            collectionRow(entry)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: .spacing.base,
                                        leading: .spacing.x6,
                                        bottom: .spacing.base,
                                        trailing: .spacing.x6
                                    )
                                )
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .frame(maxWidth: .maxWidth.appContent)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("history.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.ecoInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Subviews

private extension EcoHistoryView {

    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing.x2) {
                FilterChip(label: "history.all_filter".localized, systemImage: "list.bullet", isSelected: selectedFilter == nil, color: .ecoPrimary) {
                    withAnimation(.spring(response: Double.duration.regular)) { selectedFilter = nil }
                }
                ForEach(filterCategories) { category in
                    FilterChip(label: category.displayName, systemImage: category.systemImage, isSelected: selectedFilter == category, color: category.color) {
                        withAnimation(.spring(response: Double.duration.regular)) { selectedFilter = selectedFilter == category ? nil : category }
                    }
                }
            }
            .padding(.horizontal, .spacing.x6)
        }
    }

    var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacing.micro) {
                Text("history.collections_count".localized(with: entries.count))
                    .font(.system(size: .fontSize.small, weight: .bold))
                    .foregroundColor(.ecoSmoke)
                let totalCO2 = entries.reduce(0.0) { $0 + $1.co2Saved }
                Text(String(format: "history.co2_avoided".localized, totalCO2))
                    .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoPrimary)
            }
            Spacer()
            let totalXP = entries.reduce(0) { $0 + $1.xpEarned }
            HStack(spacing: .spacing.base) {
                Image(systemName: "star.fill").foregroundColor(.xpGold).font(.system(size: .iconSize.xsmall))
                Text("common.xp_total".localized(with: totalXP)).font(.system(size: .fontSize.xsmall, weight: .bold)).foregroundColor(.xpGold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }

    var emptyState: some View {
        VStack(spacing: .spacing.x6) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath").font(.system(size: .iconSize.display)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textLow))
            Text("history.empty.title".localized).font(.system(size: .fontSize.large, weight: .medium)).foregroundColor(.ecoSmoke)
            Text("history.empty.description".localized).font(.system(size: .fontSize.small)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textLow)).multilineTextAlignment(.center)
            Spacer()
        }
    }

    func collectionRow(_ entry: CollectionEntry) -> some View {
        let category = entry.category ?? .biodegradable
        return HStack(spacing: .spacing.x4) {
            Image(systemName: category.systemImage)
                .font(.system(size: .iconSize.medium)).foregroundColor(category.color)
                .frame(width: .size.historyCategoryIcon, height: .size.historyCategoryIcon)
                .background(Circle().fill(category.color.opacity(Double.opacity.badge)))

            VStack(alignment: .leading, spacing: .spacing.micro) {
                Text(category.displayName).font(.system(size: .fontSize.medium, weight: .semibold)).foregroundColor(.ecoSmoke)
                HStack(spacing: .spacing.x2) {
                    Text("common.co2_mass".localized(with: entry.co2Saved))
                        .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoPrimary)
                    Text("•").foregroundColor(.ecoSmoke.opacity(Double.opacity.subtleDivider))
                    Text("common.percent".localized(with: Int(entry.confidence * 100)))
                        .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textLow))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: .spacing.micro) {
                HStack(spacing: .spacing.micro) {
                    Image(systemName: "star.fill").font(.system(size: .iconSize.tiny)).foregroundColor(.xpGold)
                    Text("common.xp_gain".localized(with: entry.xpEarned)).font(.system(size: .fontSize.xsmall, weight: .bold)).foregroundColor(.xpGold)
                }
                Text(entry.timestamp, style: .date).font(.system(size: .fontSize.tiny)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textLow))
                Text(entry.timestamp, style: .time).font(.system(size: .fontSize.tiny)).foregroundColor(.ecoSmoke.opacity(Double.opacity.textLow))
            }
        }
        .padding(.horizontal, .spacing.x2)
        .padding(.vertical, .spacing.x3)
        .background(
            RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                .fill(Color.white.opacity(Double.opacity.surfaceSubtle))
                .overlay(
                    RoundedRectangle(cornerRadius: .borderRadius.mediumPlus)
                        .stroke(Color.surfaceStroke, lineWidth: .lineWidth.hairline)
                )
        )
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let label: String
    let systemImage: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing.base) {
                Image(systemName: systemImage).font(.system(size: .iconSize.xsmall))
                Text(label).font(.system(size: .fontSize.xsmall, weight: isSelected ? .bold : .regular))
            }
            .padding(.horizontal, .spacing.x4)
            .padding(.vertical, .spacing.x2)
            .background(Capsule().fill(isSelected ? color.opacity(Double.opacity.overlaySoft) : Color.white.opacity(Double.opacity.surfaceMuted)))
            .overlay(Capsule().strokeBorder(isSelected ? color : .clear, lineWidth: .lineWidth.thin))
            .foregroundColor(isSelected ? color : .ecoSmoke.opacity(Double.opacity.textDim))
        }
    }
}

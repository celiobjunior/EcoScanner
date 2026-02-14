import SwiftUI

// MARK: - EcoHistoryView

struct EcoHistoryView: View {

    @EnvironmentObject var profileManager: UserProfileManager
    @State private var selectedFilter: WasteCategory? = nil

    private var entries: [CollectionEntry] {
        let all = profileManager.fetchHistory()
        if let filter = selectedFilter {
            return all.filter { $0.categoryRawValue == filter.rawValue }
        }
        return all
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ecoInk.ignoresSafeArea()

                VStack(spacing: 0) {
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
                .frame(maxWidth: 1000)
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
                    withAnimation(.spring(response: 0.3)) { selectedFilter = nil }
                }
                ForEach(WasteCategory.allCases) { category in
                    FilterChip(label: category.displayName, systemImage: category.systemImage, isSelected: selectedFilter == category, color: category.color) {
                        withAnimation(.spring(response: 0.3)) { selectedFilter = selectedFilter == category ? nil : category }
                    }
                }
            }
            .padding(.horizontal, .spacing.x6)
        }
    }

    var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
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
                Image(systemName: "star.fill").foregroundColor(.xpGold).font(.system(size: 12))
                Text("common.xp_total".localized(with: totalXP)).font(.system(size: .fontSize.xsmall, weight: .bold)).foregroundColor(.xpGold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.spacing.x4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.surfaceStroke, lineWidth: 1))
        )
    }

    var emptyState: some View {
        VStack(spacing: .spacing.x6) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath").font(.system(size: 48)).foregroundColor(.ecoSmoke.opacity(0.62))
            Text("history.empty.title".localized).font(.system(size: .fontSize.large, weight: .medium)).foregroundColor(.ecoSmoke)
            Text("history.empty.description".localized).font(.system(size: .fontSize.small)).foregroundColor(.ecoSmoke.opacity(0.62)).multilineTextAlignment(.center)
            Spacer()
        }
    }

    func collectionRow(_ entry: CollectionEntry) -> some View {
        let category = entry.category ?? .biodegradable
        return HStack(spacing: .spacing.x4) {
            Image(systemName: category.systemImage)
                .font(.system(size: 20)).foregroundColor(category.color)
                .frame(width: 44, height: 44)
                .background(Circle().fill(category.color.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName).font(.system(size: .fontSize.medium, weight: .semibold)).foregroundColor(.ecoSmoke)
                HStack(spacing: .spacing.x2) {
                    Text("common.co2_mass".localized(with: entry.co2Saved))
                        .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoPrimary)
                    Text("•").foregroundColor(.ecoSmoke.opacity(0.6))
                    Text("common.percent".localized(with: Int(entry.confidence * 100)))
                        .font(.system(size: .fontSize.xsmall)).foregroundColor(.ecoSmoke.opacity(0.62))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.xpGold)
                    Text("common.xp_gain".localized(with: entry.xpEarned)).font(.system(size: .fontSize.xsmall, weight: .bold)).foregroundColor(.xpGold)
                }
                Text(entry.timestamp, style: .time).font(.system(size: 10)).foregroundColor(.ecoSmoke.opacity(0.62))
            }
        }
        .padding(.horizontal, .spacing.x2)
        .padding(.vertical, .spacing.x3)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.surfaceStroke, lineWidth: 1))
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
                Image(systemName: systemImage).font(.system(size: 12))
                Text(label).font(.system(size: .fontSize.xsmall, weight: isSelected ? .bold : .regular))
            }
            .padding(.horizontal, .spacing.x4)
            .padding(.vertical, .spacing.x2)
            .background(Capsule().fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.08)))
            .overlay(Capsule().strokeBorder(isSelected ? color : .clear, lineWidth: 1.5))
            .foregroundColor(isSelected ? color : .ecoSmoke.opacity(0.68))
        }
    }
}

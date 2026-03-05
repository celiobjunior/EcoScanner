import Foundation

// MARK: - Achievement

struct Achievement: Identifiable, Sendable {
    let id: String
    let systemImage: String
    let requirement: AchievementRequirement

    var title: String { "achievement.\(id).title".localized }
    var description: String { "achievement.\(id).desc".localized }

    static let all: [Achievement] = [
        Achievement(id: "first_collection", systemImage: "medal.fill", requirement: .totalCollections(1)),
        Achievement(id: "collector_10", systemImage: "target", requirement: .totalCollections(10)),
        Achievement(id: "collector_50", systemImage: "star.fill", requirement: .totalCollections(50)),
        Achievement(id: "collector_100", systemImage: "diamond.fill", requirement: .totalCollections(100)),
        Achievement(id: "streak_3", systemImage: "flame.fill", requirement: .streakDays(3)),
        Achievement(id: "streak_7", systemImage: "flame.fill", requirement: .streakDays(7)),
        Achievement(id: "streak_30", systemImage: "sparkles", requirement: .streakDays(30)),
        Achievement(id: "plastic_25", systemImage: "arrow.3.trianglepath", requirement: .categoryCollections(.plastic, 25)),
        Achievement(id: "paper_25", systemImage: "doc.fill", requirement: .categoryCollections(.paper, 25)),
        Achievement(id: "glass_25", systemImage: "wineglass.fill", requirement: .categoryCollections(.glass, 25)),
        Achievement(id: "metal_25", systemImage: "cylinder.fill", requirement: .categoryCollections(.metal, 25)),
        Achievement(id: "cardboard_50", systemImage: "shippingbox.fill", requirement: .categoryCollections(.cardboard, 50)),
        Achievement(id: "electronic_25", systemImage: "desktopcomputer", requirement: .categoryCollections(.electronic, 25)),
        Achievement(id: "biodegradable_25", systemImage: "leaf.fill", requirement: .categoryCollections(.biodegradable, 25)),
        Achievement(id: "textile_25", systemImage: "tshirt.fill", requirement: .categoryCollections(.textile, 25)),
        Achievement(id: "co2_1kg", systemImage: "globe.americas.fill", requirement: .co2Saved(1.0)),
        Achievement(id: "co2_10kg", systemImage: "globe.europe.africa.fill", requirement: .co2Saved(10.0)),
        Achievement(id: "level_warrior", systemImage: "shield.fill", requirement: .levelReached(5)),
        Achievement(id: "level_legend", systemImage: "crown.fill", requirement: .levelReached(8)),
    ]
}

// MARK: - AchievementRequirement

enum AchievementRequirement: Sendable {
    case totalCollections(Int)
    case categoryCollections(WasteCategory, Int)
    case streakDays(Int)
    case co2Saved(Double)
    case levelReached(Int)

    var summary: String {
        switch self {
        case .totalCollections(let n):
            return "achievement.req.total_collections".localized(with: n)
        case .categoryCollections(let cat, let n):
            return "achievement.req.category_collections".localized(with: n, cat.displayName)
        case .streakDays(let n):
            return "achievement.req.streak_days".localized(with: n)
        case .co2Saved(let kg):
            return "achievement.req.co2_saved".localized(with: kg)
        case .levelReached(let lvl):
            return "achievement.req.level_reached".localized(with: lvl)
        }
    }
}

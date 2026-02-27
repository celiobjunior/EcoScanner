import Foundation
import SwiftData
import SwiftUI

// MARK: - UserProfileManager

@MainActor
class UserProfileManager: ObservableObject {

    @Published var profile: UserProfile
    @Published private(set) var newlyUnlockedAchievements: [Achievement] = []
    @Published private(set) var pendingLevelUp: EcoLevel?
    @Published private(set) var pendingUnlockedAchievements: [Achievement] = []

    var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.profile = UserProfileManager.fetchOrCreateProfile(context: modelContext)
    }

    // MARK: - Actions

    func recordCollection(category: WasteCategory, confidence: Double) -> CollectionEntry {
        let previousLevel = profile.currentLevel
        let streakMultiplier = min(1.0 + Double(profile.currentStreak) * 0.1, 2.0)

        let entry = CollectionEntry.create(
            category: category,
            confidence: confidence,
            streakMultiplier: streakMultiplier
        )

        profile.totalXP += entry.xpEarned
        profile.totalCollections += 1
        profile.totalCO2Saved += entry.co2Saved
        profile.updateStreak()

        checkAchievements()

        let newLevel = profile.currentLevel
        pendingLevelUp = newLevel.rawValue > previousLevel.rawValue ? newLevel : nil
        pendingUnlockedAchievements = newlyUnlockedAchievements

        modelContext.insert(entry)
        save()

        return entry
    }

    func fetchHistory(limit: Int? = nil) -> [CollectionEntry] {
        var descriptor = FetchDescriptor<CollectionEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func collectionCount(for category: WasteCategory) -> Int {
        let rawValue = category.rawValue
        let predicate = #Predicate<CollectionEntry> { $0.categoryRawValue == rawValue }
        var descriptor = FetchDescriptor<CollectionEntry>(predicate: predicate)
        descriptor.fetchLimit = nil
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func consumeLevelUp() -> EcoLevel? {
        defer { pendingLevelUp = nil }
        return pendingLevelUp
    }

    func consumeUnlockedAchievements() -> [Achievement] {
        defer {
            pendingUnlockedAchievements = []
            newlyUnlockedAchievements = []
        }
        return pendingUnlockedAchievements
    }

    func undoCollection(_ entry: CollectionEntry) {
        profile.totalXP = max(0, profile.totalXP - entry.xpEarned)
        profile.totalCollections = max(0, profile.totalCollections - 1)
        profile.totalCO2Saved = max(0, profile.totalCO2Saved - entry.co2Saved)
        modelContext.delete(entry)
        save()
    }
}

// MARK: - Private

private extension UserProfileManager {

    static func fetchOrCreateProfile(context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let newProfile = UserProfile()
        context.insert(newProfile)
        try? context.save()
        return newProfile
    }

    func save() {
        try? modelContext.save()
    }

    func checkAchievements() {
        newlyUnlockedAchievements = []
        for achievement in Achievement.all {
            guard !profile.unlockedAchievementIDs.contains(achievement.id) else { continue }
            let isUnlocked: Bool
            switch achievement.requirement {
            case .totalCollections(let count):
                isUnlocked = profile.totalCollections >= count
            case .categoryCollections(let category, let count):
                isUnlocked = collectionCount(for: category) >= count
            case .streakDays(let days):
                isUnlocked = profile.currentStreak >= days
            case .co2Saved(let amount):
                isUnlocked = profile.totalCO2Saved >= amount
            case .levelReached(let level):
                isUnlocked = profile.currentLevel.rawValue >= level
            }
            if isUnlocked {
                profile.unlockedAchievementIDs.append(achievement.id)
                newlyUnlockedAchievements.append(achievement)
            }
        }
    }
}

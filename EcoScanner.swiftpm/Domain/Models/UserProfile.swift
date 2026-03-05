import Foundation
import SwiftData

// MARK: - UserProfile

@Model
final class UserProfile {
    var name: String
    var totalXP: Int
    var currentStreak: Int
    var lastCollectionDate: Date?
    var totalCollections: Int
    var totalCO2Saved: Double
    var unlockedAchievementIDs: [String]

    init(
        name: String = "profile.default_name".localized,
        totalXP: Int = 0,
        currentStreak: Int = 0,
        totalCollections: Int = 0,
        totalCO2Saved: Double = 0,
        unlockedAchievementIDs: [String] = []
    ) {
        self.name = name
        self.totalXP = totalXP
        self.currentStreak = currentStreak
        self.totalCollections = totalCollections
        self.totalCO2Saved = totalCO2Saved
        self.unlockedAchievementIDs = unlockedAchievementIDs
    }

    // MARK: - Level System

    var currentLevel: EcoLevel {
        EcoLevel.level(for: totalXP)
    }

    var nextLevel: EcoLevel? {
        EcoLevel.nextLevel(after: currentLevel)
    }

    var levelProgress: Double {
        guard let nextLevel else { return 1.0 }
        let currentMin = currentLevel.minXP
        let nextMin = nextLevel.minXP
        guard nextMin > currentMin else { return 1.0 }
        let currentXP = max(0, min(totalXP, nextMin) - currentMin)
        return Double(currentXP) / Double(nextMin - currentMin)
    }

    var xpToNextLevel: Int {
        guard let nextLevel else { return 0 }
        return max(0, nextLevel.minXP - totalXP)
    }

    var xpIntoCurrentLevel: Int {
        max(0, totalXP - currentLevel.minXP)
    }

    var xpRequiredForCurrentStep: Int {
        guard let nextLevel else { return 0 }
        return max(0, nextLevel.minXP - currentLevel.minXP)
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let lastDate = lastCollectionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if diff == 1 {
                currentStreak += 1
            } else if diff > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        lastCollectionDate = .now
    }
}

// MARK: - EcoLevel

enum EcoLevel: Int, Comparable, CaseIterable, Codable, Sendable {
    case ecoIniciante  = 1
    case ecoAprendiz   = 2
    case ecoColetor    = 3
    case ecoGuardiao   = 4
    case ecoWarrior    = 5
    case ecoHeroi      = 6
    case ecoChampion   = 7
    case ecoLenda      = 8

    var displayName: String {
        let key: String
        switch self {
        case .ecoIniciante:  key = "eco_iniciante"
        case .ecoAprendiz:   key = "eco_aprendiz"
        case .ecoColetor:    key = "eco_coletor"
        case .ecoGuardiao:   key = "eco_guardiao"
        case .ecoWarrior:    key = "eco_warrior"
        case .ecoHeroi:      key = "eco_heroi"
        case .ecoChampion:   key = "eco_champion"
        case .ecoLenda:      key = "eco_lenda"
        }
        return "level.\(key)".localized
    }

    var systemImage: String {
        switch self {
        case .ecoIniciante:  return "leaf"
        case .ecoAprendiz:   return "leaf.fill"
        case .ecoColetor:    return "tree.fill"
        case .ecoGuardiao:   return "shield.fill"
        case .ecoWarrior:    return "shield.checkered"
        case .ecoHeroi:      return "figure.run"
        case .ecoChampion:   return "trophy.fill"
        case .ecoLenda:      return "crown.fill"
        }
    }

    var minXP: Int {
        switch self {
        case .ecoIniciante:  return 0
        case .ecoAprendiz:   return 50
        case .ecoColetor:    return 200
        case .ecoGuardiao:   return 500
        case .ecoWarrior:    return 1000
        case .ecoHeroi:      return 1800
        case .ecoChampion:   return 3000
        case .ecoLenda:      return 5000
        }
    }

    static func level(for xp: Int) -> EcoLevel {
        for level in allCases.reversed() {
            if xp >= level.minXP { return level }
        }
        return .ecoIniciante
    }

    static func nextLevelXP(after level: EcoLevel) -> Int {
        guard let idx = allCases.firstIndex(of: level),
              idx + 1 < allCases.count else { return level.minXP }
        return allCases[idx + 1].minXP
    }

    static func nextLevel(after level: EcoLevel) -> EcoLevel? {
        guard let idx = allCases.firstIndex(of: level),
              idx + 1 < allCases.count else { return nil }
        return allCases[idx + 1]
    }

    static func < (lhs: EcoLevel, rhs: EcoLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

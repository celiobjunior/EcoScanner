import Foundation
import SwiftData

// MARK: - CollectionEntry

@Model
final class CollectionEntry {
    var categoryRawValue: String
    var confidence: Double
    var xpEarned: Int
    var co2Saved: Double
    var timestamp: Date

    var category: WasteCategory? {
        WasteCategory(rawValue: categoryRawValue)
    }

    init(category: WasteCategory, confidence: Double, xpEarned: Int, co2Saved: Double) {
        self.categoryRawValue = category.rawValue
        self.confidence = confidence
        self.xpEarned = xpEarned
        self.co2Saved = co2Saved
        self.timestamp = .now
    }

    static func create(category: WasteCategory, confidence: Double, streakMultiplier: Double = 1.0) -> CollectionEntry {
        let baseXP = category.xpValue
        let adjustedXP = Int(Double(baseXP) * streakMultiplier)
        let co2 = category.co2Impact

        return CollectionEntry(
            category: category,
            confidence: confidence,
            xpEarned: adjustedXP,
            co2Saved: co2
        )
    }
}

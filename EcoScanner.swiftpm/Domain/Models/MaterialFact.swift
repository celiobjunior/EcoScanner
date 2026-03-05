import Foundation

// MARK: - MaterialFact

struct MaterialFact: Codable, Identifiable, Sendable {
    let id: String
    let category: String
    let factKey: String
    let isPositive: Bool
    let source: String?

    var fact: String { factKey.localized }

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case factKey = "fact"
        case isPositive
        case source
    }

    static func loadFacts() -> [MaterialFact] {
        let url = Bundle.main.url(
            forResource: "MaterialFacts",
            withExtension: "json",
            subdirectory: "Data"
        ) ?? Bundle.main.url(forResource: "MaterialFacts", withExtension: "json")

        guard let url,
              let data = try? Data(contentsOf: url),
              let facts = try? JSONDecoder().decode([MaterialFact].self, from: data) else {
            return []
        }
        return facts
    }

    static func randomFact(for category: WasteCategory) -> MaterialFact {
        let facts = loadFacts().filter { $0.category == category.rawValue }
        return facts.randomElement() ?? MaterialFact(
            id: "default",
            category: category.rawValue,
            factKey: "fact.default",
            isPositive: true,
            source: nil
        )
    }
}

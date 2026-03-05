import SwiftUI

// MARK: - WasteCategory

enum WasteCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case plastic
    case glass
    case metal
    case paper
    case cardboard
    case electronic
    case biodegradable
    case textile

    var id: String { rawValue }

    // Matches the classifier labels in EcoScanner.mlmodelc:
    // BIODEGRADABLE, CARDBOARD, ELECTRONIC, GLASS, METAL, PAPER, PLASTIC, TEXTILE
    static let modelSupportedCases: [WasteCategory] = [
        .biodegradable,
        .cardboard,
        .electronic,
        .glass,
        .metal,
        .paper,
        .plastic,
        .textile,
    ]

    var displayName: String {
        "category.\(rawValue)".localized
    }

    var disposalInstruction: String {
        "category.disposal.\(rawValue)".localized
    }

    var systemImage: String {
        switch self {
        case .plastic:       return "waterbottle.fill"
        case .glass:         return "wineglass.fill"
        case .metal:         return "cylinder.fill"
        case .paper:         return "doc.fill"
        case .cardboard:     return "shippingbox.fill"
        case .electronic:    return "desktopcomputer"
        case .biodegradable: return "leaf.fill"
        case .textile:       return "tshirt.fill"
        }
    }

    var color: Color {
        switch self {
        case .plastic:       return .wastePlastic
        case .glass:         return .wasteGlass
        case .metal:         return .wasteMetal
        case .paper:         return .wastePaper
        case .cardboard:     return .wasteCardboard
        case .electronic:    return .wasteElectronic
        case .biodegradable: return .wasteBiodegradable
        case .textile:       return .wasteTextile
        }
    }

    var xpValue: Int {
        switch self {
        case .plastic, .paper:       return 10
        case .glass, .metal:         return 15
        case .cardboard:             return 12
        case .electronic:            return 25
        case .biodegradable:         return 8
        case .textile:               return 20
        }
    }

    var co2Impact: Double {
        switch self {
        case .plastic:       return 0.08
        case .glass:         return 0.31
        case .metal:         return 0.45
        case .paper:         return 0.04
        case .cardboard:     return 0.06
        case .electronic:    return 1.20
        case .biodegradable: return 0.02
        case .textile:       return 0.35
        }
    }
}

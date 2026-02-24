import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Primary brand
    static let ecoPrimary = Color(hex: 0x64A30E)
    static let ecoLight   = Color(hex: 0xD9F99C)
    static let ecoDark    = Color(hex: 0x156534)
    static let ecoInk     = Color(hex: 0x0E1618)
    static let ecoSmoke   = Color(hex: 0xF6F6F6)
    static let ecoSeaDeep = Color(hex: 0x156534)
    static let ecoSeaShore = Color(hex: 0x64A30E)

    // Semantic
    static let textPrimary   = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let cardBackground = Color(.secondarySystemBackground)
    static let surfaceGlass = Color.white.opacity(Double.opacity.glass)
    static let surfaceStroke = Color.white.opacity(Double.opacity.glow)

    // Accents
    static let xpGold       = Color(hex: 0xFFB800)
    static let streakOrange = Color(hex: 0xFF6B35)
    static let achievementLocked = Color(hex: 0xC86C66)

    // Waste categories
    static let wastePlastic = Color(hex: 0xFDE68A)
    static let wasteGlass = Color(hex: 0x99F6E4)
    static let wasteMetal = Color(hex: 0xCBD5E1)
    static let wastePaper = Color(hex: 0x93C5FD)
    static let wasteCardboard = Color(hex: 0xEBC9A8)
    static let wasteElectronic = Color(hex: 0xFCA5A5)
    static let wasteBiodegradable = Color(hex: 0xC4B5FD)
    static let wasteTextile = Color(hex: 0xD8B4FE)

    // Gradients
    static let ecoGradientStart = Color(hex: 0xD9F99C)
    static let ecoGradientMid   = Color(hex: 0x64A30E)
    static let ecoGradientEnd   = Color(hex: 0x156534)

    // Hex initializer
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

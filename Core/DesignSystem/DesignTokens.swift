import SwiftUI

// MARK: - Design Tokens

extension CGFloat {
    enum spacing {
        static let none: CGFloat  = 0
        static let hairline: CGFloat = 1
        static let micro: CGFloat = 2
        static let base: CGFloat  = 4
        static let x2: CGFloat    = 8
        static let x3: CGFloat    = 12
        static let x4: CGFloat    = 16
        static let x5: CGFloat    = 20
        static let x6: CGFloat    = 24
        static let x7: CGFloat    = 28
        static let x8: CGFloat    = 32
        static let x9: CGFloat    = 36
        static let x10: CGFloat   = 40
        static let x11: CGFloat   = 44
        static let x12: CGFloat   = 48
        static let x14: CGFloat   = 56
        static let x16: CGFloat   = 64
    }

    enum fontSize {
        static let tiny: CGFloat   = 10
        static let caption: CGFloat = 11
        static let xsmall: CGFloat = 12
        static let smallPlus: CGFloat = 13
        static let small: CGFloat  = 14
        static let medium: CGFloat = 16
        static let large: CGFloat  = 20
        static let title: CGFloat  = 22
        static let big: CGFloat    = 24
        static let xlarge: CGFloat = 28
        static let xxlarge: CGFloat = 30
        static let huge: CGFloat   = 32
        static let display: CGFloat = 36
        static let hero: CGFloat   = 48
        static let jumbo: CGFloat  = 50
        static let mega: CGFloat   = 56
    }

    enum borderRadius {
        static let xsmall: CGFloat = 4
        static let compact: CGFloat = 6
        static let small: CGFloat  = 8
        static let smallPlus: CGFloat = 10
        static let medium: CGFloat = 12
        static let mediumPlus: CGFloat = 14
        static let large: CGFloat  = 16
        static let largePlus: CGFloat = 18
        static let xlarge: CGFloat = 20
        static let xl: CGFloat     = 24
    }

    enum lineSpacing {
        static let compact: CGFloat = 3
        static let regular: CGFloat = 4
    }

    enum lineWidth {
        static let hairline: CGFloat = 1
        static let thin: CGFloat = 1.5
        static let regular: CGFloat = 2
        static let strong: CGFloat = 4
        static let scannerGuide: CGFloat = 10
        static let debugBox: CGFloat = 2.4
    }

    enum iconSize {
        static let tiny: CGFloat = 10
        static let caption: CGFloat = 11
        static let xsmall: CGFloat = 12
        static let small: CGFloat = 14
        static let medium: CGFloat = 20
        static let title: CGFloat = 22
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 28
        static let xxlarge: CGFloat = 30
        static let hero: CGFloat = 36
        static let giant: CGFloat = 40
        static let display: CGFloat = 48
        static let jumbo: CGFloat = 50
        static let mega: CGFloat = 56
    }

    enum size {
        static let indicator: CGFloat = 8
        static let indicatorActive: CGFloat = 24
        static let categoryBadgeIconSlot: CGFloat = 30
        static let supportCardIconSlot: CGFloat = 26
        static let creditsCardIconSlot: CGFloat = 22
        static let levelIconSlot: CGFloat = 34
        static let historyCategoryIcon: CGFloat = 44
        static let carbonCardIcon: CGFloat = 56
        static let onboardingHeroLogo: CGFloat = 220
        static let onboardingSecondaryHero: CGFloat = 110
        static let scannerLogo: CGFloat = 28
        static let supportLogo: CGFloat = 44
        static let creditsLogo: CGFloat = 80
        static let scannerGuideFrame: CGFloat = 248
        static let scannerGuideCornerLength: CGFloat = 70
        static let scannerButtonOuter: CGFloat = 84
        static let scannerButtonInner: CGFloat = 66
        static let achievementCardWidth: CGFloat = 150
        static let achievementCardHeight: CGFloat = 136
        static let achievementSheetHeight: CGFloat = 540
        static let minimumProgressFill: CGFloat = 6
        static let feedbackHiddenOffset: CGFloat = 600
    }

    enum progress {
        static let thin: CGFloat = 8
        static let regular: CGFloat = 12
    }

    enum maxWidth {
        static let scannerBanner: CGFloat = 420
        static let feedbackCard: CGFloat = 500
        static let guidedCard: CGFloat = 520
        static let onboardingText: CGFloat = 620
        static let onboardingCards: CGFloat = 680
        static let onboardingTutorial: CGFloat = 760
        static let helpContent: CGFloat = 780
        static let creditsContent: CGFloat = 840
        static let appContent: CGFloat = 1000
    }

    enum shadow {
        static let smallRadius: CGFloat = 3
        static let mediumRadius: CGFloat = 6
        static let largeRadius: CGFloat = 20
        static let heroRadius: CGFloat = 26
        static let smallYOffset: CGFloat = 2
        static let mediumYOffset: CGFloat = 8
        static let largeYOffset: CGFloat = 10
    }

    enum blur {
        static let subtle: CGFloat = 1.2
    }

    enum scale {
        static let hidden: CGFloat = 0.5
        static let reduced: CGFloat = 0.65
        static let normal: CGFloat = 1
        static let pulse: CGFloat = 1.12
    }
}

extension Double {
    enum opacity {
        static let none: Double = 0
        static let surfaceSubtle: Double = 0.06
        static let surfaceMuted: Double = 0.08
        static let glass: Double = 0.12
        static let track: Double = 0.14
        static let badge: Double = 0.15
        static let chip: Double = 0.16
        static let strokeSoft: Double = 0.18
        static let overlaySoft: Double = 0.2
        static let glow: Double = 0.25
        static let overlayStrong: Double = 0.28
        static let gradientSoft: Double = 0.3
        static let pageIndicator: Double = 0.35
        static let scrim: Double = 0.4
        static let scannerFocus: Double = 0.42
        static let disabled: Double = 0.45
        static let disabledStrong: Double = 0.48
        static let accentStroke: Double = 0.56
        static let subtleDivider: Double = 0.6
        static let textLow: Double = 0.62
        static let iconInactive: Double = 0.65
        static let textMuted: Double = 0.66
        static let textDim: Double = 0.68
        static let controlDisabled: Double = 0.7
        static let cardOverlay: Double = 0.72
        static let textSubdued: Double = 0.74
        static let textSecondary: Double = 0.78
        static let textTertiary: Double = 0.8
        static let textStrong: Double = 0.82
        static let textBody: Double = 0.84
        static let textHeadline: Double = 0.85
        static let textPrimary: Double = 0.86
        static let textEmphasis: Double = 0.9
        static let nearOpaque: Double = 0.92
        static let almostOpaque: Double = 0.95
        static let opaque: Double = 1
    }

    enum duration {
        static let quick: Double = 0.18
        static let fast: Double = 0.2
        static let short: Double = 0.25
        static let regular: Double = 0.3
        static let medium: Double = 0.35
        static let feedback: Double = 0.4
        static let long: Double = 0.5
        static let extraLong: Double = 0.6
        static let slow: Double = 0.8
        static let scannerPulse: Double = 1.15
        static let onboardingGradient: Double = 9
        static let notificationLifetime: Double = 2.6
    }

    enum damping {
        static let medium: Double = 0.8
        static let responsive: Double = 0.82
        static let snappy: Double = 0.86
    }
}

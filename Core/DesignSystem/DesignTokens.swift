import SwiftUI

// MARK: - Design Tokens

extension CGFloat {
    enum spacing {
        static let base: CGFloat  = 4
        static let x2: CGFloat    = 8
        static let x3: CGFloat    = 12
        static let x4: CGFloat    = 16
        static let x5: CGFloat    = 20
        static let x6: CGFloat    = 24
        static let x8: CGFloat    = 32
        static let x10: CGFloat   = 40
        static let x12: CGFloat   = 48
        static let x16: CGFloat   = 64
    }

    enum fontSize {
        static let xsmall: CGFloat = 12
        static let small: CGFloat  = 14
        static let medium: CGFloat = 16
        static let large: CGFloat  = 20
        static let big: CGFloat    = 24
        static let huge: CGFloat   = 32
    }

    enum borderRadius {
        static let small: CGFloat  = 8
        static let medium: CGFloat = 12
        static let large: CGFloat  = 16
        static let xl: CGFloat     = 24
    }
}

import SwiftUI

/// Design tokens ported from DESIGN.md ("Translational Surface").
/// Typography uses the system font for now — DESIGN.md specifies Roboto Flex,
/// which can be dropped in as a bundled font later without changing call sites.
enum Theme {

    enum Colors {
        static let background = Color(hex: 0x131314)
        static let surfaceContainerLowest = Color(hex: 0x0E0E0E)
        static let surfaceContainerLow = Color(hex: 0x1E1F20)
        static let surfaceContainer = Color(hex: 0x282A2C)
        static let surfaceContainerHigh = Color(hex: 0x313335)
        static let surfaceContainerHighest = Color(hex: 0x3B3D40)

        static let primary = Color(hex: 0x8AB4F8)
        static let onPrimary = Color(hex: 0x041E49)
        static let secondaryContainer = Color(hex: 0x004A77)
        static let onSecondaryContainer = Color(hex: 0xC2E7FF)

        static let textPrimary = Color(hex: 0xE8EAED)
        static let textSecondary = Color(hex: 0x9AA0A6)

        static let outline = Color(hex: 0x444746)
        static let outlineVariant = Color(hex: 0x3C4043)

        static let success = Color(hex: 0x81C995)
        static let error = Color(hex: 0xFFB4AB)
    }

    enum Typography {
        static let displayLg = Font.system(size: 44, weight: .regular)
        static let headlineLg = Font.system(size: 32, weight: .regular)
        static let headlineLgMobile = Font.system(size: 26, weight: .medium)
        static let headlineMd = Font.system(size: 24, weight: .regular)
        static let headlineSm = Font.system(size: 20, weight: .medium)
        static let titleLg = Font.system(size: 18, weight: .medium)
        static let titleMd = Font.system(size: 16, weight: .medium)
        static let bodyLg = Font.system(size: 18, weight: .regular)
        static let bodyMd = Font.system(size: 14, weight: .regular)
        static let bodySm = Font.system(size: 12, weight: .regular)
        static let labelLg = Font.system(size: 14, weight: .medium)
        static let labelMd = Font.system(size: 12, weight: .medium)
        static let labelSm = Font.system(size: 11, weight: .medium)
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let full: CGFloat = 9999
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

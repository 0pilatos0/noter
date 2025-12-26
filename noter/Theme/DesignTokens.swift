import SwiftUI

// MARK: - Color Tokens
enum NoterColors {
    // Surface colors - simplified to 3 perceptually distinct levels
    static let surfaceSubtle = Color.primary.opacity(0.03)
    static let surfaceLight = Color.primary.opacity(0.06)
    static let surfaceMedium = Color.primary.opacity(0.10)

    // Stroke/border colors
    static let strokeSubtle = Color.primary.opacity(0.10)
    static let strokeLight = Color.primary.opacity(0.15)

    // Divider
    static let divider = Color.primary.opacity(0.10)

    // Status colors with semantic backgrounds
    enum Status {
        static let success = Color.green
        static let successBackground = Color.green.opacity(0.12)

        static let error = Color.red
        static let errorBackground = Color.red.opacity(0.12)

        static let warning = Color.orange
        static let warningBackground = Color.orange.opacity(0.12)

        static let info = Color.blue
        static let infoBackground = Color.blue.opacity(0.12)
    }
}

// MARK: - Typography Scale
enum NoterTypography {
    // Headers
    static let header = Font.system(size: 13, weight: .semibold)
    static let sectionHeader = Font.system(size: 13, weight: .medium)

    // Body text
    static let body = Font.system(size: 12)
    static let bodyMedium = Font.system(size: 12, weight: .medium)

    // Small/Caption
    static let caption = Font.system(size: 11)
    static let captionMedium = Font.system(size: 11, weight: .medium)
    static let captionSmall = Font.system(size: 10)

    // Monospaced
    static let mono = Font.system(size: 11, design: .monospaced)
    static let monoSmall = Font.system(size: 10, design: .monospaced)

    // Special
    static let keyboardHint = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - Spacing Scale (based on 4px grid)
enum NoterSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Icon Sizes (standardized)
enum NoterIconSize {
    static let xs: CGFloat = 10
    static let sm: CGFloat = 12  // Standard size for most icons
    static let md: CGFloat = 14
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let hero: CGFloat = 32
    static let heroLarge: CGFloat = 56
}

// MARK: - Corner Radii
enum NoterRadius {
    static let xs: CGFloat = 2
    static let sm: CGFloat = 4
    static let md: CGFloat = 6
    static let lg: CGFloat = 8
    static let xl: CGFloat = 10
}

// MARK: - Animation Durations
enum NoterAnimation {
    static let fast: Double = 0.15
    static let normal: Double = 0.2
    static let slow: Double = 0.3

    static var fastSpring: Animation {
        .spring(response: 0.25, dampingFraction: 0.7)
    }

    static var normalSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }
}

// MARK: - Status Banner Timing (unified)
enum NoterStatusTiming {
    static let autoDismiss: UInt64 = 3_000_000_000  // 3 seconds for all statuses
}

// MARK: - Template Colors
enum NoterTemplateColor: String, CaseIterable {
    case blue, purple, green, orange, red, yellow, gray, pink, teal

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .yellow: return .yellow
        case .gray: return .gray
        case .pink: return .pink
        case .teal: return .teal
        }
    }

    static func from(_ name: String) -> Color {
        (NoterTemplateColor(rawValue: name) ?? .blue).color
    }
}

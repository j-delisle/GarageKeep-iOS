import SwiftUI

// MARK: - Color + Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Color Tokens

extension Color {
    // Backgrounds
    static let appBackground      = Color(hex: "0E1117")
    static let appSurface         = Color(hex: "1A1D24")
    static let appSurfaceElevated = Color(hex: "22262F")
    static let appBorder          = Color(hex: "2A2D38")

    // Brand
    static let appPrimary         = Color(hex: "0DF2DF")

    // Text
    static let textPrimary        = Color(hex: "FFFFFF")
    static let textSecondary      = Color(hex: "8C8FA3")
    static let textTertiary       = Color(hex: "55596A")

    // Status
    static let statusAlert        = Color(hex: "F97316")
    static let statusDanger       = Color(hex: "EF4444")
    static let statusSuccess      = Color(hex: "22C55E")
}

// MARK: - Spacing

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum Radius {
    static let badge:  CGFloat = 6
    static let button: CGFloat = 10
    static let card:   CGFloat = 12
    static let sheet:  CGFloat = 20
}

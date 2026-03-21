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
// Full spec: design.md §2

extension Color {
    // Base surfaces — layered from floor up
    static let appBackground          = Color(hex: "131315") // surface (floor)
    static let appSurface             = Color(hex: "1b1b1d") // surface-container-low
    static let appSurfaceContainerHigh = Color(hex: "272729") // surface-container-high
    static let appSurfaceElevated     = Color(hex: "353437") // surface-container-highest (modals, active cards)

    // Brand — "Teal Ignition". Use sparingly for accents and CTAs only.
    static let appPrimary             = Color(hex: "59d9d9")
    static let appPrimaryContainer    = Color(hex: "00a8a8") // gradient endpoint for primary CTAs

    // Accent — use for "Service Overdue" / warning states (contrasts teal)
    static let tertiary               = Color(hex: "ffb691")

    // Text
    static let textPrimary            = Color(hex: "FFFFFF")
    static let textSecondary          = Color(hex: "8C8FA3")
    static let textTertiary           = Color(hex: "55596A")

    // Status
    static let statusAlert            = Color(hex: "F97316")
    static let statusDanger           = Color(hex: "EF4444")
    static let statusSuccess          = Color(hex: "22C55E")

    // Ghost border — outline-variant for the rare "needs extra definition" case.
    // Per design rules: never use as a full-opacity 1px divider.
    // Usage: .stroke(Color.appBorder.opacity(0.15)) or .stroke(Color.appBorder)
    static let appBorder              = Color(hex: "4a4a4f")
}

// MARK: - Gradients

extension LinearGradient {
    /// Primary CTA gradient — primary → primaryContainer at 135°. Use for filled action buttons.
    static let primaryCTA = LinearGradient(
        colors: [.appPrimary, .appPrimaryContainer],
        startPoint: UnitPoint(x: 0.15, y: 0),
        endPoint: UnitPoint(x: 0.85, y: 1)
    )
}

// MARK: - Spacing
// Outer screen margin: spacing.outer (24pt / 1.5rem)
// Internal card padding: spacing.md (16pt)

enum Spacing {
    static let xs:    CGFloat = 4
    static let sm:    CGFloat = 8
    static let md:    CGFloat = 16
    static let lg:    CGFloat = 20
    static let outer: CGFloat = 24  // Required outer margin for all screens (1.5rem)
    static let xl:    CGFloat = 32
    static let xxl:   CGFloat = 48
}

// MARK: - Corner Radius
// Cards and buttons use xl (24pt / 1.5rem) for modern iOS feel.
// Chips/badges use .infinity (full pill).

enum Radius {
    static let badge:  CGFloat = 9999 // Full pill — use for chips and status tags
    static let button: CGFloat = 24   // xl — primary and secondary buttons
    static let card:   CGFloat = 24   // xl — all cards and list containers
    static let sheet:  CGFloat = 20   // Bottom sheets / modals (top corners)
    static let input:  CGFloat = 12   // Input fields — slightly tighter than cards
}

// MARK: - Typography
// Fonts: Plus Jakarta Sans (display/headline) + Manrope (body/label/title).
// Both fonts must be added to the Xcode target (see design.md §3).
// Font.jakartaSans / Font.manrope fall back to system font if not bundled.

extension Font {
    // Display — hero numbers, odometer stats (Plus Jakarta Sans Bold, ~56pt)
    static let displayLg  = Font.custom("PlusJakartaSans-Bold",    size: 56, relativeTo: .largeTitle)
    // Stat values — card numbers like "$1,240" (Plus Jakarta Sans Bold, ~22pt)
    static let displaySm  = Font.custom("PlusJakartaSans-Bold",    size: 22, relativeTo: .title2)

    // Headline — page titles, major section headers (Plus Jakarta Sans SemiBold, ~28pt)
    static let headlineMd = Font.custom("PlusJakartaSans-SemiBold", size: 28, relativeTo: .title)

    // Title — card headers, vehicle name rows (Manrope SemiBold, ~18pt)
    static let titleMd    = Font.custom("Manrope-SemiBold",        size: 18, relativeTo: .headline)
    // Row title — list row primary text (Manrope SemiBold, ~15pt)
    static let titleSm    = Font.custom("Manrope-SemiBold",        size: 15, relativeTo: .subheadline)

    // Button label — primary/secondary button text (Manrope SemiBold, ~16pt)
    static let buttonLabel = Font.custom("Manrope-SemiBold",       size: 16, relativeTo: .body)

    // Body — general information and form content (Manrope Regular, ~14pt)
    static let bodyMd     = Font.custom("Manrope-Regular",         size: 14, relativeTo: .body)

    // Section header — uppercase section labels "DETAILS", "METADATA" (Manrope SemiBold, ~12pt)
    static let sectionHeader = Font.custom("Manrope-SemiBold",     size: 12, relativeTo: .caption)
    // Label — technical specs, metadata captions (Manrope Regular, ~11pt)
    static let labelSm    = Font.custom("Manrope-Regular",         size: 11, relativeTo: .caption2)
}

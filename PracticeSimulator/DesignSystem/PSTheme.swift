
import SwiftUI

enum PSTheme {
    static let appDisplayName = "1xBase Practice"

    static let backgroundDeep = Color(hex: 0x093663)
    static let accent = Color(hex: 0x137ECE)
    static let textPrimary = Color(hex: 0xFFFFFF)
    static let textSecondary = Color(hex: 0xDADADA)

    static let cardFill = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.12)

    static let gradientTop = Color(hex: 0x093663)
    static let gradientBottom = Color(hex: 0x137ECE).opacity(0.35)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

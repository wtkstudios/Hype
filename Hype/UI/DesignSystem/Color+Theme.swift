import SwiftUI

extension Color {
    struct HYPE {
        /// Muted Black (Backgrounds, Base)
        static let base = Color(hex: "1D1D1B")
        
        /// Seashell (Primary Text, Cards)
        static let text = Color(hex: "EAE4DA")
        
        /// Lavender (Active Tracks, Secondary Data)
        static let primary = Color(hex: "808BC5")
        
        /// Tea (Positive Trends, Stable Indicators)
        static let tea = Color(hex: "245E55")
        
        /// Tangerine (Strictly: Executions, Single Critical Highlights)
        static let tangerine = Color(hex: "ED773C")
        
        /// Red (Errors, Underperformance Drops)
        static let error = Color(hex: "C63F3E")
        
        /// Neon Green (Improving Health / Above Baseline Sparklines)
        static let neonGreen = Color(hex: "39FF14")
        
        /// Neon Red (Declining Health / Below Baseline Sparklines)
        static let neonRed = Color(hex: "FF2A2A")
        
        // Aliases for Engine compatibility
        static let energy = tangerine
    }
}

// MARK: - Graph Color Resolver
enum TrendDirection {
    case up
    case down
    case flat
}

struct GraphColorResolver {
    /// Returns the appropriate stroke color for sparklines based on trend direction.
    /// - Parameters:
    ///   - trend: The calculated trend direction (up, down, flat).
    ///   - isCritical: True if the graph is highlighting a severe condition (e.g. very negative momentum).
    static func strokeColor(trend: TrendDirection, isCritical: Bool = false) -> Color {
        switch trend {
        case .up:
            return Color.HYPE.neonGreen
        case .down:
            return isCritical ? Color.HYPE.error : Color.HYPE.neonRed
        case .flat:
            return Color.HYPE.primary // Use Lavender for flat
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

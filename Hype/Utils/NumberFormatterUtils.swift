import Foundation

struct NumberFormatterUtils {
    
    /// Formats a large integer into a compact, readable string (e.g., 12500 -> "12.5K")
    static func formatCompact(number: Int) -> String {
        let doubleNum = Double(number)
        let sign = number < 0 ? "-" : ""
        let absNum = abs(doubleNum)
        
        switch absNum {
        case 1_000_000_000...:
            let formatted = absNum / 1_000_000_000
            return "\(sign)\(String(format: "%.1f", formatted).replacingOccurrences(of: ".0", with: ""))B"
        case 1_000_000...:
            let formatted = absNum / 1_000_000
            return "\(sign)\(String(format: "%.1f", formatted).replacingOccurrences(of: ".0", with: ""))M"
        case 10_000...:
            let formatted = absNum / 1_000
            return "\(sign)\(String(format: "%.1f", formatted).replacingOccurrences(of: ".0", with: ""))K"
        case 1_000...:
            // For numbers like 1,200 we might want 1.2K
            let formatted = absNum / 1_000
            return "\(sign)\(String(format: "%.1f", formatted).replacingOccurrences(of: ".0", with: ""))K"
        default:
            return "\(number)"
        }
    }
}

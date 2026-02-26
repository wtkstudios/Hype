import Foundation

// A) NEW MODELS FOR DRIVERS REDESIGN

enum DriverStrength: String, Codable {
    case strong, good, neutral, weak
}

enum DriverTrend: String, Codable {
    case rising, flat, falling
}

struct KeyValueRow: Codable, Identifiable {
    let id: String
    let key: String
    let value: String
}

struct DriverInsight: Codable, Identifiable {
    enum Kind: String, Codable {
        case velocity = "velocity"
        case acceleration = "accel."
        case shares = "shares"
        case engagement = "engagement"
    }
    
    let id: String
    let kind: Kind
    let strength: DriverStrength
    let trend: DriverTrend
    let metricLabel: String          // e.g. "Views / min"
    let metricValue: String          // e.g. "52.4"
    let secondaryLabel: String       // e.g. "+42% vs baseline" (Legacy or explicit formatting)
    let relativeStatusText: String?  // e.g. "Above usual", "Below usual", "On usual"
    let confidenceLabel: String      // Optional textual (legacy) or descriptive
    let explanation: String          // 1–2 lines: why it matters
    // New Analytical Extensions for Polish
    let impactScore: Double          // Absolute intensity vs baseline for sorting
    let confidencePercent: Int       // 0-100 numeric equivalent
    let ageBucketLabel: String       // e.g. "0-15m"
    let lastUpdateString: String     // e.g. "Just now" or "2m ago"
    
    let details: [KeyValueRow]       // expanded sheet rows
}

struct DriverPack: Codable {
    let insights: [DriverInsight]     // 4 insights, fixed order
    let contribution: [String: Int]   // contribution points out of 100 (optional)
}

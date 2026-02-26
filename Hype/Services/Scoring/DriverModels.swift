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
        case velocity, acceleration, shares, engagement
    }
    
    let id: String
    let kind: Kind
    let strength: DriverStrength
    let trend: DriverTrend
    let metricLabel: String          // e.g. "Views / min"
    let metricValue: String          // e.g. "52.4"
    let secondaryLabel: String       // e.g. "+42% vs baseline"
    let confidenceLabel: String      // e.g. "High confidence"
    let explanation: String          // 1–2 lines: why it matters
    let details: [KeyValueRow]       // expanded sheet rows
}

struct DriverPack: Codable {
    let insights: [DriverInsight]     // 4 insights, fixed order
    let contribution: [String: Int]   // contribution points out of 100 (optional)
}

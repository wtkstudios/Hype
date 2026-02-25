import Foundation
import GRDB

struct BaselineProfile: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var accountId: String
    var computedAt: Date
    var windowDays: Int
    var medianViews_15m: Int?
    var medianViews_30m: Int?
    var medianViews_60m: Int?
    var medianViews_24h: Int?
    var volatilityIndex: Double?
}

enum DistributionPhase: String, Codable {
    case testing = "Testing"
    case expanding = "Expanding"
    case secondaryPush = "Secondary Push"
    case plateau = "Plateau"
    case reignite = "Reignite"
    case unknown = "Unknown"
}

struct PhasePrediction: Codable {
    var currentPhase: DistributionPhase
    var nextPhase: DistributionPhase
    var nextPhaseProbability: Double // 0-1
    var updatedAt: Date
}

struct ForecastSnapshot: Codable {
    var videoId: String
    var computedAt: Date
    var expected24hLow: Int
    var expected24hHigh: Int
    var confidence: ConfidenceLevel
    var trajectorySummary: String
}

enum ConfidenceLevel: String, Codable {
    case high = "High"
    case medium = "Med"
    case low = "Low"
}

struct AccountMomentumSnapshot: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var accountId: String
    var date: Date
    var index: Int
    var volatility: Double
    var stability: StabilityLevel
}

enum StabilityLevel: String, Codable {
    case stable = "Stable"
    case moderate = "Moderate"
    case volatile = "Volatile"
}

enum RecommendedAction: String, Codable {
    case respondToComment = "Respond with video to top comment"
    case postFollowUp = "Post follow-up within 30 minutes"
    case pinRefreshComment = "Pin/refresh comment strategy"
    case prepareAlternateHook = "Prepare alternate hook variant"
    case repostWindow = "Suggest repost window later"
    case noAction = "Leave it (No Action)"
}

struct HypeScoreSnapshot: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var videoId: String
    var capturedAt: Date
    var hypeScore: Double // 0-100
    var velocityScore: Double
    var deviationFromBaseline: Double
    var breakoutProbability: Double // 0-1
    var phase: String // Stored as String for GRDB
    var recommendedAction: String // Stored as String for GRDB
}

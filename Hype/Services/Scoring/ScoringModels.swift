import Foundation

// A) DATA MODELS

enum TimeBucket: String, CaseIterable, Codable {
    case min0_15, min15_30, min30_60, hr1_2, hr2_6, hr6_24, day1_7
}

struct VideoSnapshot: Codable, Identifiable {
    var id: String { "\(videoId)-\(timestamp.timeIntervalSince1970)" }
    let videoId: String
    let timestamp: Date
    let createdAt: Date
    let views: Int
    let likes: Int
    let comments: Int
    let shares: Int
}

struct BaselineBucket: Codable {
    let bucket: TimeBucket
    let medianVPM: Double
    let iqrVPM: Double
    let medianEPR: Double
    let iqrEPR: Double
    let medianSPM: Double
    let iqrSPM: Double
    let medianACC: Double
    let iqrACC: Double
    let sampleSize: Int
}

enum PostPhase: String, Codable {
    case testing, expanding, secondaryPush, plateau, reignite
}

struct HypeComputation: Codable {
    let hypeScore: Int          // 0–100
    let hypeRaw01: Double       // 0–1
    let confidence01: Double    // 0–1
    let phase: PostPhase
    let breakoutProb01: Double  // 0–1
}

enum StabilityLabel: String, Codable {
    case low, moderate, high
}

struct AccountOverallComputation: Codable {
    let overallScore: Int       // 0–100
    let stability: StabilityLabel
    let volatilityStd: Double   // raw std dev of recent HYPE
}

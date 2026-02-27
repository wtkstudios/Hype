import Foundation

// MARK: - Account Dashboard Intelligence Models

/// Live totals displayed in the hero metric strip
struct AccountMetrics {
    var followers: Int
    var totalLikes: Int
    var totalComments: Int
    var totalShares: Int
    var totalViews: Int
    
    /// Simulated mock data
    static let mock = AccountMetrics(
        followers: 128400,
        totalLikes: 4_200_000,
        totalComments: 312_500,
        totalShares: 98_700,
        totalViews: 18_500_000
    )
}

/// 30-Day projected growth based on rolling average
struct GrowthProjection {
    var projectedFollowers: Int      // delta
    var projectedViews: Int          // delta
    var projectedEngagement: Double  // % change
    var cadenceActual: Double        // posts/week actual
    var cadenceRecommended: Double   // posts/week recommended
    var momentumDecayDays: Int?      // days until decay risk (nil if safe)
    
    static let mock = GrowthProjection(
        projectedFollowers: 4_200,
        projectedViews: 1_250_000,
        projectedEngagement: 3.8,
        cadenceActual: 3.2,
        cadenceRecommended: 4.0,
        momentumDecayDays: 3
    )
}

/// Milestone projection — e.g. "Next 10K Followers: ~42 days"
struct MilestoneProjection: Identifiable {
    var id: String { label }
    var label: String           // "10K Followers"
    var daysRemaining: Int
    var icon: String            // SF Symbol
    
    static let mock: [MilestoneProjection] = [
        MilestoneProjection(label: "150K Followers", daysRemaining: 42, icon: "person.2.fill"),
        MilestoneProjection(label: "20M Views", daysRemaining: 18, icon: "eye.fill"),
        MilestoneProjection(label: "5M Likes", daysRemaining: 61, icon: "heart.fill")
    ]
}

/// Hype Health Score — composite 0-100
struct HypeHealthScore {
    var score: Int               // 0–100
    var growthConsistency: Double // 0–1
    var volatility: Double       // 0–1 (lower is better)
    var engagementStability: Double // 0–1
    var cadenceAlignment: Double // 0–1
    
    static let mock = HypeHealthScore(
        score: 78,
        growthConsistency: 0.82,
        volatility: 0.35,
        engagementStability: 0.71,
        cadenceAlignment: 0.88
    )
}

/// Growth data point for trajectory graph
struct GrowthDataPoint: Identifiable {
    var id: Int { dayOffset }
    var dayOffset: Int          // 0 = today, -1 = yesterday, etc.
    var value: Double
    var isProjected: Bool
}

/// Timeframe for the dashboard
enum DashboardTimeframe: String, CaseIterable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case oneYear = "1Y"
    
    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .oneYear: return 365
        }
    }
}

/// Metric type for growth trajectory graph
enum GrowthMetricType: String, CaseIterable {
    case followers = "Followers"
    case views = "Views"
    case engagement = "Engagement"
    case shares = "Shares"
    case comments = "Comments"
}

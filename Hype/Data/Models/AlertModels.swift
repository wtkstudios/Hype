import Foundation

enum AlertEventType: String, Codable {
    case momentumSpike = "MomentumSpike"
    case underperform = "Underperform"
    case secondaryWindow = "SecondaryWindow"
    case accountShift = "AccountShift"
    case volatilityAnomaly = "VolatilityAnomaly"
}

struct AlertEvent: Codable {
    var id: String
    var accountId: String
    var videoId: String? // Nullable if event is account-wide
    var type: AlertEventType
    var createdAt: Date
    var deliveredAt: Date?
    var messageTitle: String
    var messageBody: String
    var severity: String // "info", "warn", "critical"
    var triggerMetric: String
    var actionLine: String
    var isRead: Bool
}

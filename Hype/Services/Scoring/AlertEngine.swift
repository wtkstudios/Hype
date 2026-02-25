import Foundation
import UserNotifications

class AlertEngine {
    static let shared = AlertEngine()
    
    // Evaluates the latest scan for any actionable alerts
    func evaluateForAlerts(video: Video, score: HypeScoreSnapshot, baseline: BaselineProfile) throws {
        
        var generatedAlert: AlertEvent? = nil
        let ageMinutes = score.capturedAt.timeIntervalSince(video.createdAt) / 60.0
        
        // Rules Check
        if score.phase == DistributionPhase.expanding.rawValue && score.hypeScore > 85 && ageMinutes < 120 {
            generatedAlert = AlertEvent(
                id: UUID().uuidString,
                accountId: video.accountId,
                videoId: video.id,
                type: .momentumSpike,
                createdAt: Date(),
                deliveredAt: nil,
                messageTitle: "Momentum Spike: \(video.caption ?? "New Video")",
                messageBody: "Your video is over-indexing by \(String(format: "%.0f", score.deviationFromBaseline * 100))%. Respond to top comments now.",
                severity: "warn", // 'warn' maps to our lavender color attention level
                triggerMetric: "+\(String(format: "%.0f", score.deviationFromBaseline * 100))% VS BASELINE",
                actionLine: "Respond with Video Reply",
                isRead: false
            )
        } else if score.phase == DistributionPhase.reignite.rawValue && score.hypeScore > 75 {
            generatedAlert = AlertEvent(
                id: UUID().uuidString,
                accountId: video.accountId,
                videoId: video.id,
                type: .secondaryWindow,
                createdAt: Date(),
                deliveredAt: nil,
                messageTitle: "Secondary Push Detected",
                messageBody: "An older video is accelerating again. Post a follow-up or pin a new comment.",
                severity: "info",
                triggerMetric: "ALGORITHM EXTENDED",
                actionLine: "Post Follow-Up",
                isRead: false
            )
        } else if score.deviationFromBaseline < 0.3 && ageMinutes > 60 && ageMinutes < 120 {
             generatedAlert = AlertEvent(
                id: UUID().uuidString,
                accountId: video.accountId,
                videoId: video.id,
                type: .underperform,
                createdAt: Date(),
                deliveredAt: nil,
                messageTitle: "Underperforming Hook",
                messageBody: "Views are 70% below baseline. Consider private/repost with alternate hook.",
                severity: "critical",
                triggerMetric: "70% BELOW BASELINE",
                actionLine: "Prepare Alternate Hook",
                isRead: false
             )
        }
        
        if let alert = generatedAlert {
            try persistAndSchedule(alert: alert)
        }
    }
    
    private func persistAndSchedule(alert: AlertEvent) throws {
        // Save to DB (mock for now, we will add the GRDB table next)
        // try DatabaseManager.shared.save(alert: alert)
        
        // Schedule Local Push Notification
        let content = UNMutableNotificationContent()
        content.title = alert.messageTitle
        content.body = alert.messageBody
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: alert.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

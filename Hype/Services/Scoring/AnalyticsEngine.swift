import Foundation
import GRDB

struct DriverItem: Codable {
    var title: String
    var delta: String
    var impact: String // "Positive", "Negative", "Neutral"
}

class AnalyticsEngine {
    static let shared = AnalyticsEngine()
    
    /// MVP Baseline Builder (Generates mock baseline if no history exists for testing)
    func computeBaseline(for accountId: String) throws -> BaselineProfile {
        _ = DatabaseManager.shared.dbPool!
        
        // In a real scenario, we would `GROUP BY` time buckets.
        // For Milestone 2 MVP, we simulate a constant baseline.
        
        let baseline = BaselineProfile(
            id: UUID().uuidString,
            accountId: accountId,
            computedAt: Date(),
            windowDays: 30,
            medianViews_15m: 500,
            medianViews_30m: 1000,
            medianViews_60m: 3000,
            medianViews_24h: 15000,
            volatilityIndex: 1.2
        )
        
        try DatabaseManager.shared.save(baseline: baseline)
        return baseline
    }
    
    /// HYPE Scoring v1
    /// DeviationFromBaseline (40%), VelocityAcceleration (25%), ShareSaveQuality (20%), CommentVelocity (10%), StabilityAdjustment (5%)
    func evaluateHypeScore(for video: Video, currentSnapshot: VideoMetricsSnapshot, previousSnapshot: VideoMetricsSnapshot?, baseline: BaselineProfile) throws -> (HypeScoreSnapshot, PhasePrediction, ForecastSnapshot, [DriverItem], Double) {
        
        // 1. Calculate Age (Minutes)
        let ageMinutes = currentSnapshot.capturedAt.timeIntervalSince(video.createdAt) / 60.0
        
        // Determine Expected Baseline Views based on age bucket MVP
        var expectedViews = 0.0
        if ageMinutes <= 15 {
            expectedViews = Double(baseline.medianViews_15m ?? 500)
        } else if ageMinutes <= 30 {
            expectedViews = Double(baseline.medianViews_30m ?? 1000)
        } else if ageMinutes <= 60 {
            expectedViews = Double(baseline.medianViews_60m ?? 3000)
        } else {
            expectedViews = Double(baseline.medianViews_24h ?? 15000)
        }
        
        // 2. Deviation Score (40%)
        let deviationRatio = min(Double(currentSnapshot.views) / max(1.0, expectedViews), 3.0) // Cap at 3x
        let deviationScore = (deviationRatio / 3.0) * 40.0
        
        // 3. Velocity and Acceleration (25%) -> Simplified for MVP
        let timeDeltaMinutes = previousSnapshot != nil ? currentSnapshot.capturedAt.timeIntervalSince(previousSnapshot!.capturedAt) / 60.0 : ageMinutes
        let viewDelta = currentSnapshot.views - (previousSnapshot?.views ?? 0)
        let velocityPerMinute = Double(viewDelta) / max(1.0, timeDeltaMinutes)
        
        // MVP: Normalizing velocity logic - if 100 views/min is "insane", we cap around there
        let velocityScore = min(velocityPerMinute / 100.0, 1.0) * 25.0
        
        // 4. Quality (Shares/Saves) (20%)
        let qualityActions = currentSnapshot.shares + currentSnapshot.saves
        let qualityRatio = Double(qualityActions) / max(1.0, Double(currentSnapshot.views))
        // Target 2% share/save rate as max points
        let qualityScore = min(qualityRatio / 0.02, 1.0) * 20.0
        
        // 5. Comments (10%)
        let commentRatio = Double(currentSnapshot.comments) / max(1.0, Double(currentSnapshot.views))
        // Target 1% comment rate
        let commentScore = min(commentRatio / 0.01, 1.0) * 10.0
        
        // 6. Stability (5%)
        let stabilityPenalty = 5.0 * (min((baseline.volatilityIndex ?? 1.0), 2.0) - 1.0) // High volatility lowers score
        let stabilityScore = max(0, 5.0 - stabilityPenalty)
        
        // 7. Aggregate
        let rawScore = deviationScore + velocityScore + qualityScore + commentScore + stabilityScore
        let finalScore = min(max(rawScore, 0), 100) // Clamp 0-100
        
        // Phase Detection v1
        let phasePrediction = determinePhasePrediction(ageMinutes: ageMinutes, score: finalScore, deviation: deviationRatio)
        
        // recommended action + transparency drivers
        let (action, drivers, actionConfidence) = determineAction(phase: phasePrediction.currentPhase, score: finalScore, deviationRatio: deviationRatio)
        
        // basic forecast
        let forecast = computeForecast(videoId: video.id, ageMinutes: ageMinutes, currentViews: currentSnapshot.views, baseline: baseline, deviationRatio: deviationRatio)
        
        let scoreRecord = HypeScoreSnapshot(
            id: UUID().uuidString,
            videoId: video.id,
            capturedAt: currentSnapshot.capturedAt,
            hypeScore: finalScore,
            velocityScore: velocityScore,
            deviationFromBaseline: deviationRatio,
            breakoutProbability: finalScore > 75 ? 0.8 : (finalScore > 50 ? 0.4 : 0.1),
            phase: phasePrediction.currentPhase.rawValue,
            recommendedAction: action.rawValue
        )
        
        try DatabaseManager.shared.save(score: scoreRecord)
        return (scoreRecord, phasePrediction, forecast, drivers, actionConfidence)
    }
    
    private func determinePhasePrediction(ageMinutes: Double, score: Double, deviation: Double) -> PhasePrediction {
        let current: DistributionPhase
        var next: DistributionPhase = .unknown
        var nextProb: Double = 0.0
        
        if ageMinutes < 20 && deviation < 1.2 {
            current = .testing
            next = .expanding
            nextProb = 0.4
        } else if score > 70 && deviation > 1.5 {
            current = .expanding
            next = .hyper
            nextProb = 0.75
        } else if ageMinutes > 60 && score > 85 {
            current = .hyper
            next = .plateau
            nextProb = 0.90
        } else if ageMinutes > 120 && deviation < 1.0 {
            current = .plateau
            next = .reignite
            nextProb = 0.10
        } else {
            current = .unknown
        }
        
        return PhasePrediction(currentPhase: current, nextPhase: next, nextPhaseProbability: nextProb, updatedAt: Date())
    }
    
    private func determineAction(phase: DistributionPhase, score: Double, deviationRatio: Double) -> (RecommendedAction, [DriverItem], Double) {
        var drivers: [DriverItem] = []
        var action: RecommendedAction = .noAction
        var confidence: Double = 0.5
        
        if phase == .expanding && score > 80 {
            action = .respondToComment
            confidence = 0.88
            drivers = [
                DriverItem(title: "Velocity", delta: "+\(Int(deviationRatio * 100))%", impact: "Positive"),
                DriverItem(title: "Phase", delta: phase.rawValue, impact: "Positive")
            ]
        } else if phase == .hyper {
            action = .postFollowUp
            confidence = 0.70
            drivers = [
                DriverItem(title: "Distribution", delta: "Algorithm Extended", impact: "Positive")
            ]
        } else if phase == .testing && score < 40 {
            action = .prepareAlternateHook
            confidence = 0.60
            drivers = [
                DriverItem(title: "Velocity", delta: "-\(Int(100 - (deviationRatio * 100)))%", impact: "Negative"),
                DriverItem(title: "Deviation", delta: "Below Baseline", impact: "Negative")
            ]
        }
        
        return (action, drivers, confidence)
    }
    
    private func computeForecast(videoId: String, ageMinutes: Double, currentViews: Int, baseline: BaselineProfile, deviationRatio: Double) -> ForecastSnapshot {
        let baseline24h = min(Double(baseline.medianViews_24h ?? 15000), 5000000)
        let multiplier = max(0.5, min(deviationRatio, 5.0))
        let expectedMid = baseline24h * multiplier
        
        let confidence: ConfidenceLevel = ageMinutes > 60 ? .high : (ageMinutes > 30 ? .medium : .low)
        let trajectoryText = "Current momentum suggests \(deviationRatio > 1.2 ? "expansion" : "a plateau") with \(Int((deviationRatio/5.0)*100))% chance of breakout."
        
        return ForecastSnapshot(
            videoId: videoId,
            computedAt: Date(),
            expected24hLow: Int(expectedMid * 0.8),
            expected24hHigh: Int(expectedMid * 1.2),
            confidence: confidence,
            trajectorySummary: trajectoryText
        )
    }
}

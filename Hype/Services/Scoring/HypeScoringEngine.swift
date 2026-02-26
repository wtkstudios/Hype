import Foundation

// F) HYPE SCORING ENGINE (POST OUT OF 100)

class HypeScoringEngine {
    
    func computeHype(
        accountId: String,
        videoId: String,
        current: VideoSnapshot,
        previous: VideoSnapshot?,
        baselineBuckets: [TimeBucket: BaselineBucket],
        recentHypeHistory: [Int],
        now: Date
    ) -> HypeComputation {
        
        // 1) ageMin
        let ageMin = current.timestamp.timeIntervalSince(current.createdAt) / 60.0
        
        // 2) bucket
        let bucket = TimeBucket.bucket(forAgeMinutes: ageMin)
        
        // 3) baseline
        let baseline = baselineBuckets[bucket] ?? BaselineBucket(
            bucket: bucket,
            medianVPM: 0.0, iqrVPM: RobustStats.epsilon,
            medianEPR: 0.0, iqrEPR: RobustStats.epsilon,
            medianSPM: 0.0, iqrSPM: RobustStats.epsilon,
            medianACC: 0.0, iqrACC: RobustStats.epsilon,
            sampleSize: 0
        )
        
        // 4) compute dtMin
        let dtMin: Double
        if let prev = previous {
            dtMin = max(0.5, current.timestamp.timeIntervalSince(prev.timestamp) / 60.0)
        } else {
            dtMin = 5.0 // low confidence initial assumption
        }
        
        // 5) compute metrics
        let prevViews = previous?.views ?? 0
        let prevShares = previous?.shares ?? 0
        
        let deltaViews = max(0, current.views - prevViews)
        let vpm = Double(deltaViews) / dtMin
        
        let deltaShares = max(0, current.shares - prevShares)
        let spm = Double(deltaShares) / dtMin
        
        let epr = Double(current.likes + current.comments + current.shares) / max(Double(current.views), 1.0)
        
        // Derive prevVPM from snapshot lifetime up to previous observation
        let inferredPrevVPM: Double
        if let prev = previous {
            let prevAgeMin = prev.timestamp.timeIntervalSince(prev.createdAt) / 60.0
            inferredPrevVPM = Double(prev.views) / max(0.5, prevAgeMin)
        } else {
            inferredPrevVPM = 0.0
        }
        let computedAcc = vpm - inferredPrevVPM
        
        // 6) normalize
        let sVel = RobustStats.sigmoid(RobustStats.robustZScore(value: vpm, median: baseline.medianVPM, iqr: baseline.iqrVPM))
        let sShare = RobustStats.sigmoid(RobustStats.robustZScore(value: spm, median: baseline.medianSPM, iqr: baseline.iqrSPM))
        let sEng = RobustStats.sigmoid(RobustStats.robustZScore(value: epr, median: baseline.medianEPR, iqr: baseline.iqrEPR))
        let sAcc = RobustStats.sigmoid(RobustStats.robustZScore(value: computedAcc, median: baseline.medianACC, iqr: baseline.iqrACC))
        
        // 7) bucket-dependent weights
        let wVel, wShare, wAcc, wEng: Double
        switch bucket {
        case .min0_15, .min15_30, .min30_60:
            wVel = 0.35; wShare = 0.30; wAcc = 0.20; wEng = 0.15
        case .hr1_2, .hr2_6:
            wVel = 0.35; wShare = 0.25; wAcc = 0.15; wEng = 0.25
        case .hr6_24, .day1_7:
            wVel = 0.30; wShare = 0.20; wAcc = 0.10; wEng = 0.40
        }
        
        // 8) raw
        let hRaw01 = RobustStats.clamp(wVel * sVel + wShare * sShare + wAcc * sAcc + wEng * sEng, 0.0, 1.0)
        
        // 9) confidence
        let baselineConf = RobustStats.clamp(Double(baseline.sampleSize) / 20.0, 0.30, 1.0)
        let snapshotConf = previous == nil ? 0.6 : 1.0
        let confidence01 = RobustStats.clamp(baselineConf * snapshotConf, 0.30, 1.0)
        
        // 10) adjust
        let hAdj01 = RobustStats.clamp(0.5 + (hRaw01 - 0.5) * confidence01, 0.0, 1.0)
        
        // 11) scale to score
        let hypeScore = RobustStats.clamp(Int(round(100.0 * hAdj01)), 0, 100)
        
        // 12) breakout prob
        let breakoutProb01 = RobustStats.clamp(RobustStats.sigmoid((Double(hypeScore) - 70.0) / 8.0) * confidence01, 0.0, 1.0)
        
        // 13) phase detection
        let phase = PhaseDetector.phase(hypeScore: hypeScore, previousHypes: Array(recentHypeHistory.suffix(2)), postAgeMinutes: ageMin)
        
        return HypeComputation(
            hypeScore: hypeScore,
            hypeRaw01: hRaw01,
            confidence01: confidence01,
            phase: phase,
            breakoutProb01: breakoutProb01,
            weights: HypeWeights(vel: wVel, shares: wShare, accel: wAcc, engage: wEng)
        )
    }
}

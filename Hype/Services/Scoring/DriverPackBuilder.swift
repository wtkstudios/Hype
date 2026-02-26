import Foundation

// B) COMPUTE DRIVER METRICS (LOGIC)

class DriverPackBuilder {
    
    // Formatting Helpers
    private func formatNumber(_ num: Double) -> String {
        return num < 10.0 ? String(format: "%.2f", num) : String(format: "%.0f", num)
    }
    
    private func formatPct(_ pct: Double) -> String {
        let prefix = pct >= 0 ? "+" : ""
        return "\(prefix)\(Int(round(pct)))%"
    }
    
    private func determineStrength(ratio: Double) -> DriverStrength {
        if ratio >= 1.40 { return .strong }
        if ratio >= 1.15 { return .good }
        if ratio >= 0.90 { return .neutral }
        return .weak
    }
    
    private func determineTrend(current: Double, history: [Double]) -> DriverTrend {
        let validHistory = history.filter { !$0.isNaN }
        guard !validHistory.isEmpty else { return .flat }
        
        let avgPrev = validHistory.reduce(0, +) / Double(validHistory.count)
        guard avgPrev > 0 else {
            return current > 0 ? .rising : .flat
        }
        
        if current > avgPrev * 1.05 { return .rising }
        if current < avgPrev * 0.95 { return .falling }
        return .flat
    }
    
    private func determineConfidence(confidence01: Double) -> String {
        if confidence01 >= 0.80 { return "High confidence" }
        if confidence01 >= 0.55 { return "Med confidence" }
        return "Low confidence"
    }
    
    // Main computation
    func buildDriverPack(
        currentSnapshot: VideoSnapshot,
        previousSnapshot: VideoSnapshot?,
        prevPrevSnapshot: VideoSnapshot?,
        baseline: BaselineBucket,
        confidence01: Double,
        recentVpmHistory: [Double],
        recentAccHistory: [Double],
        recentSpmHistory: [Double]
    ) -> DriverPack {
        
        let eps = RobustStats.epsilon
        let ageMin = currentSnapshot.timestamp.timeIntervalSince(currentSnapshot.createdAt) / 60.0
        
        let dtMin: Double
        if let prev = previousSnapshot {
            dtMin = max(0.5, currentSnapshot.timestamp.timeIntervalSince(prev.timestamp) / 60.0)
        } else {
            dtMin = 5.0
        }
        
        // Raw values
        let deltaViews = max(0, currentSnapshot.views - (previousSnapshot?.views ?? 0))
        let deltaShares = max(0, currentSnapshot.shares - (previousSnapshot?.shares ?? 0))
        
        let vpm = Double(deltaViews) / dtMin
        let spm = Double(deltaShares) / dtMin
        let epr = Double(currentSnapshot.likes + currentSnapshot.comments + currentSnapshot.shares) / max(Double(currentSnapshot.views), 1.0)
        let sv = Double(currentSnapshot.shares) / max(Double(currentSnapshot.views), 1.0)
        
        // Acceleration needs previous vpm
        let vpmPrev: Double
        if let prev = previousSnapshot, let pp = prevPrevSnapshot {
            let dtPrev = max(0.5, prev.timestamp.timeIntervalSince(pp.timestamp) / 60.0)
            let prevDViews = max(0, prev.views - pp.views)
            vpmPrev = Double(prevDViews) / dtPrev
        } else if let prev = previousSnapshot {
            let prevAgeMin = prev.timestamp.timeIntervalSince(prev.createdAt) / 60.0
            vpmPrev = Double(prev.views) / max(0.5, prevAgeMin)
        } else {
            vpmPrev = 0.0
        }
        
        let acc = vpm - vpmPrev
        
        // Baseline Ratios
        let vpmRatio = vpm / max(baseline.medianVPM, eps)
        let spmRatio = spm / max(baseline.medianSPM, eps)
        let eprRatio = epr / max(baseline.medianEPR, eps)
        
        // ACC is different, can be negative, standard ratio isn't as clean.
        // We use Z-Score converted to a pseudo ratio where 0 Z is 1.0 ratio
        let accZ = RobustStats.robustZScore(value: acc, median: baseline.medianACC, iqr: baseline.iqrACC)
        // map Z to ratio: Z=0 -> 1.0, Z=1 -> 1.25, Z=-1 -> 0.75 roughly for strength mapping
        let accRatio = 1.0 + (accZ * 0.25)
        
        // Percentages vs Baseline
        let vpmPct = (vpmRatio - 1.0) * 100.0
        let spmPct = (spmRatio - 1.0) * 100.0
        let eprPct = (eprRatio - 1.0) * 100.0
        // For ACC, direct display of how much faster/slower it's accelerating vs baseline is tough,
        // let's show Z-score based delta or just raw difference
        
        let confLabel = determineConfidence(confidence01: confidence01)
        
        // -----------------------------------------------------
        // Insights Construction
        // -----------------------------------------------------
        var insights: [DriverInsight] = []
        
        // 1. Velocity
        let velMetricLabel = vpm > 10 ? "Views / min" : "Views / hr"
        let velMetricValue = vpm > 10 ? formatNumber(vpm) : formatNumber(vpm * 60)
        
        insights.append(DriverInsight(
            id: "vel_1",
            kind: .velocity,
            strength: determineStrength(ratio: vpmRatio),
            trend: determineTrend(current: vpm, history: recentVpmHistory),
            metricLabel: velMetricLabel,
            metricValue: velMetricValue,
            secondaryLabel: "\(formatPct(vpmPct)) vs baseline",
            confidenceLabel: confLabel,
            explanation: "Measures distribution speed at this point in the lifecycle.",
            details: [
                KeyValueRow(id: "vel_cur", key: "Current (VPM)", value: formatNumber(vpm)),
                KeyValueRow(id: "vel_med", key: "Baseline (VPM)", value: formatNumber(baseline.medianVPM)),
                KeyValueRow(id: "vel_age", key: "Age bucket", value: baseline.bucket.rawValue),
                KeyValueRow(id: "vel_time", key: "Last update", value: currentSnapshot.timestamp.formatted(date: .omitted, time: .shortened))
            ]
        ))
        
        // 2. Acceleration
        let accTrend = determineTrend(current: acc, history: recentAccHistory)
        let accTrendString = accTrend == .rising ? "Rising" : (accTrend == .falling ? "Falling" : "Flat")
        insights.append(DriverInsight(
            id: "acc_1",
            kind: .acceleration,
            strength: determineStrength(ratio: accRatio),
            trend: accTrend,
            metricLabel: "Δ Views/min",
            metricValue: formatNumber(acc),
            secondaryLabel: "Trend: \(accTrendString)",
            confidenceLabel: confLabel,
            explanation: "Signals whether TikTok is increasing distribution or tapering.",
            details: [
                KeyValueRow(id: "acc_cur", key: "Current Δ", value: formatNumber(acc)),
                KeyValueRow(id: "acc_prev", key: "Previous VPM", value: formatNumber(vpmPrev)),
                KeyValueRow(id: "acc_med", key: "Baseline Δ", value: formatNumber(baseline.medianACC))
            ]
        ))
        
        // 3. Shares
        insights.append(DriverInsight(
            id: "shr_1",
            kind: .shares,
            strength: determineStrength(ratio: spmRatio),
            trend: determineTrend(current: spm, history: recentSpmHistory),
            metricLabel: "Shares / min",
            metricValue: formatNumber(spm),
            secondaryLabel: "Shares/View: \(String(format: "%.2f", sv * 100))%",
            confidenceLabel: confLabel,
            explanation: "Shares amplify reach; high share velocity often precedes secondary pushes.",
            details: [
                KeyValueRow(id: "shr_cur", key: "Current (SPM)", value: formatNumber(spm)),
                KeyValueRow(id: "shr_med", key: "Baseline (SPM)", value: formatNumber(baseline.medianSPM)),
                KeyValueRow(id: "shr_dev", key: "Deviation", value: "\(formatPct(spmPct))")
            ]
        ))
        
        // 4. Engagement
        insights.append(DriverInsight(
            id: "eng_1",
            kind: .engagement,
            strength: determineStrength(ratio: eprRatio),
            trend: .flat, // Engagement density trend is less volatile, flat by default
            metricLabel: "Engagement / view",
            metricValue: "\(String(format: "%.1f", epr * 100))%",
            secondaryLabel: "\(formatPct(eprPct)) vs baseline",
            confidenceLabel: confLabel,
            explanation: "Density of reactions per view; supports sustained distribution.",
            details: [
                KeyValueRow(id: "eng_cur", key: "Current Rate", value: "\(String(format: "%.2f", epr * 100))%"),
                KeyValueRow(id: "eng_med", key: "Baseline Rate", value: "\(String(format: "%.2f", baseline.medianEPR * 100))%"),
                KeyValueRow(id: "eng_dev", key: "Deviation", value: "\(formatPct(eprPct))")
            ]
        ))
        
        // Dynamic weight contribution mapping based on bucket
        let wVel, wShare, wAcc, wEng: Int
        switch baseline.bucket {
        case .min0_15, .min15_30, .min30_60:
            wVel = 35; wShare = 30; wAcc = 20; wEng = 15
        case .hr1_2, .hr2_6:
            wVel = 35; wShare = 25; wAcc = 15; wEng = 25
        case .hr6_24, .day1_7:
            wVel = 30; wShare = 20; wAcc = 10; wEng = 40
        }
        
        let contributionMap: [String: Int] = [
            "Velocity": wVel, "Shares": wShare, "Acceleration": wAcc, "Engagement": wEng
        ]
        
        return DriverPack(insights: insights, contribution: contributionMap)
    }
}

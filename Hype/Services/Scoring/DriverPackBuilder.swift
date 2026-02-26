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
    
    private func determineRelativeStatus(ratio: Double?) -> String? {
        guard let r = ratio, r > 0 else { return nil }
        if r >= 1.15 { return "Above usual" }
        if r <= 0.85 { return "Below usual" }
        return "On usual"
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
        recentSpmHistory: [Double],
        now: Date
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
        
        // Common Properties
        let confidenceInt = Int(round(confidence01 * 100))
        let ageLabel = baseline.bucket.rawValue
        
        let lastUpdateStr: String
        let minAgo = Int(round(now.timeIntervalSince(currentSnapshot.timestamp) / 60))
        if minAgo < 1 { lastUpdateStr = "Just now" }
        else if minAgo < 60 { lastUpdateStr = "\(minAgo)m ago" }
        else { lastUpdateStr = "\(minAgo/60)h ago" }
        
        // -----------------------------------------------------
        // Insights Construction
        // -----------------------------------------------------
        var insights: [DriverInsight] = []
        
        // 1. Velocity
        let velMetricLabel = vpm > 10 ? "Views / min" : "Views / hr"
        let velMetricValue = vpm > 10 ? formatNumber(vpm) : formatNumber(vpm * 60)
        let velImpact = abs(vpmRatio - 1.0)
        
        let velRelative = determineRelativeStatus(ratio: baseline.medianVPM > 0 ? vpmRatio : nil)
        
        insights.append(DriverInsight(
            id: "vel_1",
            kind: .velocity,
            strength: determineStrength(ratio: vpmRatio),
            trend: determineTrend(current: vpm, history: recentVpmHistory),
            metricLabel: velMetricLabel,
            metricValue: velMetricValue,
            secondaryLabel: "", // Deprecated formatting in UI
            relativeStatusText: velRelative,
            confidenceLabel: confLabel,
            explanation: "Distribution speed at this stage.",
            impactScore: velImpact,
            confidencePercent: confidenceInt,
            ageBucketLabel: ageLabel,
            lastUpdateString: lastUpdateStr,
            details: [
                KeyValueRow(id: "vel_cur", key: "Current", value: formatNumber(vpm)),
                KeyValueRow(id: "vel_med", key: "Usual", value: formatNumber(baseline.medianVPM)),
                KeyValueRow(id: "vel_time", key: "Updated", value: lastUpdateStr)
            ]
        ))
        
        // 2. Acceleration
        let accTrend = determineTrend(current: acc, history: recentAccHistory)
        let accTrendString = accTrend == .rising ? "Rising" : (accTrend == .falling ? "Falling" : "Flat")
        let accImpact = abs(accRatio - 1.0)
        
        // Spec: Acceleration keeps "Trend: Rising/Falling/Flat" and does NOT show relativeStatusText
        
        insights.append(DriverInsight(
            id: "acc_1",
            kind: .acceleration,
            strength: determineStrength(ratio: accRatio),
            trend: accTrend,
            metricLabel: "Δ Views/min",
            metricValue: formatNumber(acc),
            secondaryLabel: "Trend: \(accTrendString)",
            relativeStatusText: nil, // Retained Trend as secondary context instead
            confidenceLabel: confLabel,
            explanation: "Signals whether reach is increasing or tapering.",
            impactScore: accImpact,
            confidencePercent: confidenceInt,
            ageBucketLabel: ageLabel,
            lastUpdateString: lastUpdateStr,
            details: [
                KeyValueRow(id: "acc_cur", key: "Current", value: formatNumber(acc)),
                KeyValueRow(id: "acc_med", key: "Usual", value: formatNumber(baseline.medianACC)),
                KeyValueRow(id: "acc_time", key: "Updated", value: lastUpdateStr)
            ]
        ))
        
        // 3. Shares
        let shareImpact = abs(spmRatio - 1.0)
        
        // Spec: Shares keeps "Shares/View: X%" as the context line; do NOT show relativeStatusText.
        
        insights.append(DriverInsight(
            id: "shr_1",
            kind: .shares,
            strength: determineStrength(ratio: spmRatio),
            trend: determineTrend(current: spm, history: recentSpmHistory),
            metricLabel: "Shares / min",
            metricValue: formatNumber(spm),
            secondaryLabel: "Shares/View: \(String(format: "%.2f", sv * 100))%",
            relativeStatusText: nil, // Kept static metric definition per spec
            confidenceLabel: confLabel,
            explanation: "Shares amplify reach and can trigger secondary pushes.",
            impactScore: shareImpact,
            confidencePercent: confidenceInt,
            ageBucketLabel: ageLabel,
            lastUpdateString: lastUpdateStr,
            details: [
                KeyValueRow(id: "shr_cur", key: "Current", value: formatNumber(spm)),
                KeyValueRow(id: "shr_med", key: "Usual", value: formatNumber(baseline.medianSPM)),
                KeyValueRow(id: "shr_time", key: "Updated", value: lastUpdateStr)
            ]
        ))
        
        // 4. Engagement
        let engImpact = abs(eprRatio - 1.0)
        
        let engRelative = determineRelativeStatus(ratio: baseline.medianEPR > 0 ? eprRatio : nil)
        
        insights.append(DriverInsight(
            id: "eng_1",
            kind: .engagement,
            strength: determineStrength(ratio: eprRatio),
            trend: .flat, // Engagement density trend is less volatile, flat by default
            metricLabel: "Engagement / view",
            metricValue: "\(String(format: "%.1f", epr * 100))%",
            secondaryLabel: "", // Dropped Deviation Strings
            relativeStatusText: engRelative,
            confidenceLabel: confLabel,
            explanation: "Reactions per view supporting sustained distribution.",
            impactScore: engImpact,
            confidencePercent: confidenceInt,
            ageBucketLabel: ageLabel,
            lastUpdateString: lastUpdateStr,
            details: [
                KeyValueRow(id: "eng_cur", key: "Current", value: "\(String(format: "%.2f", epr * 100))%"),
                KeyValueRow(id: "eng_med", key: "Usual", value: "\(String(format: "%.2f", baseline.medianEPR * 100))%"),
                KeyValueRow(id: "eng_time", key: "Updated", value: lastUpdateStr)
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

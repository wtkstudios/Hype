import Foundation

// K) UNIT TEST EXAMPLES

class ScoringTests {
    
    static func runExamples() {
        print("--- Running Scoring Tests ---")
        let now = Date()
        let createdAt = now.addingTimeInterval(-3600) // 1 hour old
        
        let baselineBuckets: [TimeBucket: BaselineBucket] = [
            .hr1_2: BaselineBucket(
                bucket: .hr1_2,
                medianVPM: 10.0, iqrVPM: 2.0,
                medianEPR: 0.05, iqrEPR: 0.01,
                medianSPM: 0.01, iqrSPM: 0.005,
                medianACC: 0.0, iqrACC: 1.0,
                sampleSize: 50
            )
        ]
        
        let engine = HypeScoringEngine()
        
        // Example 1: Metrics match baseline
        let current1 = VideoSnapshot(videoId: "vid1", timestamp: now, createdAt: createdAt, views: 600, likes: 25, comments: 2, shares: 3)
        let previous1 = VideoSnapshot(videoId: "vid1", timestamp: now.addingTimeInterval(-600), createdAt: createdAt, views: 500, likes: 20, comments: 2, shares: 2)
        // dtMin = 10 mins. deltaViews = 100 -> vpm = 10. matches median 10.
        // epr = (25+2+3)/600 = 30/600 = 0.05. matches median 0.05
        // deltaShares = 1 -> spm = 0.1
        let comp1 = engine.computeHype(accountId: "acc", videoId: "vid1", current: current1, previous: previous1, baselineBuckets: baselineBuckets, recentHypeHistory: [50], now: now)
        print("1) Matches baseline HYPE: \(comp1.hypeScore)") // Should be around 50
        
        // Example 2: Breakout / above baseline
        let current2 = VideoSnapshot(videoId: "vid1", timestamp: now, createdAt: createdAt, views: 1600, likes: 100, comments: 20, shares: 30)
        let comp2 = engine.computeHype(accountId: "acc", videoId: "vid1", current: current2, previous: previous1, baselineBuckets: baselineBuckets, recentHypeHistory: [50], now: now)
        print("2) Outperforms baseline HYPE: \(comp2.hypeScore)") // Should be higher
        
        // Example 3: Overall Account decreases when post hypes drop
        let overallEngine = AccountOverallEngine()
        let posts1: [(createdAt: Date, hype: Int)] = [
            (now.addingTimeInterval(-86400 * 1), 80),
            (now.addingTimeInterval(-86400 * 2), 85),
            (now.addingTimeInterval(-86400 * 3), 90)
        ]
        let overall1 = overallEngine.computeOverall(recentPosts: posts1, now: now)
        print("3a) Overall high history: \(overall1.overallScore) | stability: \(overall1.stability)")
        
        let posts2: [(createdAt: Date, hype: Int)] = [
            (now.addingTimeInterval(-86400 * 1), 30),
            (now.addingTimeInterval(-86400 * 2), 85),
            (now.addingTimeInterval(-86400 * 3), 90)
        ]
        let overall2 = overallEngine.computeOverall(recentPosts: posts2, now: now)
        print("3b) Overall dropped history: \(overall2.overallScore) | stability: \(overall2.stability)") // Should be lower and potentially less stable
        
        print("\n--- Running DriverPackBuilder Tests ---")
        let packBuilder = DriverPackBuilder()
        
        let driverBaseline = BaselineBucket(
            bucket: .hr1_2,
            medianVPM: 10.0, iqrVPM: 2.0,
            medianEPR: 0.05, iqrEPR: 0.01,
            medianSPM: 0.01, iqrSPM: 0.005,
            medianACC: 0.0, iqrACC: 1.0,
            sampleSize: 50
        )
        
        let historyVPM = [10.0, 10.5, 9.8]
        let historyACC = [0.0, -0.2, 0.1]
        let historySPM = [0.01, 0.009, 0.011]
        
        // Case A: Metrics equal baseline -> Neutral across drivers
        let snapPrevA = VideoSnapshot(videoId: "vidA", timestamp: now.addingTimeInterval(-600), createdAt: createdAt, views: 500, likes: 20, comments: 2, shares: 2)
        // dt=10, views=+100 -> vpm=10 (1.0 ratio = Neutral)
        // shares=+0.1 -> spm=0.01 (1.0 ratio = Neutral)
        let snapCurrA = VideoSnapshot(videoId: "vidA", timestamp: now, createdAt: createdAt, views: 600, likes: 25, comments: 2, shares: 3)
        let packA = packBuilder.buildDriverPack(currentSnapshot: snapCurrA, previousSnapshot: snapPrevA, prevPrevSnapshot: nil, baseline: driverBaseline, confidence01: 0.9, recentVpmHistory: historyVPM, recentAccHistory: historyACC, recentSpmHistory: historySPM)
        print("A) Baseline Match - Vel: \(packA.insights.first(where: { $0.kind == .velocity })?.strength.rawValue ?? "") | Shr: \(packA.insights.first(where: { $0.kind == .shares })?.strength.rawValue ?? "")")
        
        // Case B: High shares velocity -> Shares = Strong
        let snapCurrB = VideoSnapshot(videoId: "vidB", timestamp: now, createdAt: createdAt, views: 600, likes: 25, comments: 2, shares: 10)
        // delta shares = +8 -> spm=0.8. (baseline=0.01, ratio=80 -> Strong)
        let packB = packBuilder.buildDriverPack(currentSnapshot: snapCurrB, previousSnapshot: snapPrevA, prevPrevSnapshot: nil, baseline: driverBaseline, confidence01: 0.9, recentVpmHistory: historyVPM, recentAccHistory: historyACC, recentSpmHistory: historySPM)
        print("B) Breakout Shares - Shr: \(packB.insights.first(where: { $0.kind == .shares })?.strength.rawValue ?? "")")
        
        // Case C: Falling velocity -> Velocity trend = Falling
        let historyVPMHigh = [20.0, 22.0, 19.5] // averge ~20.5
        let snapCurrC = VideoSnapshot(videoId: "vidC", timestamp: now, createdAt: createdAt, views: 580, likes: 20, comments: 2, shares: 2)
        // delta views = 80 -> vpm = 8. (8 is < 20.5 * 0.95 -> Falling)
        let packC = packBuilder.buildDriverPack(currentSnapshot: snapCurrC, previousSnapshot: snapPrevA, prevPrevSnapshot: nil, baseline: driverBaseline, confidence01: 0.9, recentVpmHistory: historyVPMHigh, recentAccHistory: historyACC, recentSpmHistory: historySPM)
        print("C) Falling Velocity - Trend: \(packC.insights.first(where: { $0.kind == .velocity })?.trend.rawValue ?? "")")
    }
}

import Foundation

// I) INTEGRATION SERVICE (ONE ENTRY POINT)

class AnalyticsScoringService {
    let snapshotStore: SnapshotStore
    let baselineStore: BaselineStore
    let scoreStore: ScoreStore
    
    let baselineBuilder = BaselineBuilder()
    let hypeEngine = HypeScoringEngine()
    let overallEngine = AccountOverallEngine()
    
    init(snapshotStore: SnapshotStore, baselineStore: BaselineStore, scoreStore: ScoreStore) {
        self.snapshotStore = snapshotStore
        self.baselineStore = baselineStore
        self.scoreStore = scoreStore
    }
    
    func refreshHypeForVideo(accountId: String, videoId: String) async throws {
        let now = Date()
        
        // 1) Fetch baseline
        var baselineBuckets = try await baselineStore.fetchBaseline(accountId: accountId)
        
        // If missing, build baseline
        if baselineBuckets == nil {
            let recentVideoIds = try await snapshotStore.fetchRecentVideoIds(limit: 50)
            baselineBuckets = try await baselineBuilder.buildBaseline(
                accountId: accountId,
                videoIds: recentVideoIds,
                snapshotStore: snapshotStore,
                now: now
            )
            if let buckets = baselineBuckets {
                try await baselineStore.saveBaseline(accountId: accountId, buckets: buckets)
            }
        }
        
        let buckets = baselineBuckets ?? [:]
        
        // 2) Fetch latest + previous snapshots
        let snapshots = try await snapshotStore.fetchSnapshots(videoId: videoId, since: nil)
        guard let current = snapshots.last else { return } // No data
        let previous = snapshots.count > 1 ? snapshots[snapshots.count - 2] : nil
        
        // 3) Fetch recent hypes for this video
        let recentHypes = try await scoreStore.fetchRecentHypes(accountId: accountId, limit: 3)
            .filter { $0.videoId == videoId }
            .sorted { $0.createdAt < $1.createdAt }
            .map { $0.hype }
            
        // 4) Compute hype
        let computation = hypeEngine.computeHype(
            accountId: accountId,
            videoId: videoId,
            current: current,
            previous: previous,
            baselineBuckets: buckets,
            recentHypeHistory: recentHypes,
            now: now
        )
        
        // 5) Store hype
        try await scoreStore.saveHype(accountId: accountId, videoId: videoId, computation: computation)
    }
    
    func computeOverallForAccount(accountId: String) async throws -> AccountOverallComputation {
        let now = Date()
        // 1) fetch recent hypes from ScoreStore (limit 10)
        let recentPosts = try await scoreStore.fetchRecentHypes(accountId: accountId, limit: 10)
        
        // 2) compute overall
        let mappedPosts = recentPosts.map { (createdAt: $0.createdAt, hype: $0.hype) }
        return overallEngine.computeOverall(recentPosts: mappedPosts, now: now)
    }
}

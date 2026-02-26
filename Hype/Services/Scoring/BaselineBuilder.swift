import Foundation

// E) BASELINE BUILDER (PER ACCOUNT)

class BaselineBuilder {
    func buildBaseline(
        accountId: String,
        videoIds: [String],
        snapshotStore: SnapshotStore,
        now: Date
    ) async throws -> [TimeBucket: BaselineBucket] {
        
        let sixtyDaysAgo = now.addingTimeInterval(-60 * 86400)
        
        var bucketDataVPM: [TimeBucket: [Double]] = [:]
        var bucketDataEPR: [TimeBucket: [Double]] = [:]
        var bucketDataSPM: [TimeBucket: [Double]] = [:]
        var bucketDataACC: [TimeBucket: [Double]] = [:]
        
        TimeBucket.allCases.forEach {
            bucketDataVPM[$0] = []
            bucketDataEPR[$0] = []
            bucketDataSPM[$0] = []
            bucketDataACC[$0] = []
        }
        
        var validPostsCount = 0
        
        for videoId in videoIds {
            // Fetch snapshots sorted by timestamp asc
            let snapshots = try await snapshotStore.fetchSnapshots(videoId: videoId, since: nil)
            guard let first = snapshots.first, first.createdAt >= sixtyDaysAgo else {
                continue
            }
            validPostsCount += 1
            
            var prevVpm: Double = 0.0
            
            for i in 1..<snapshots.count {
                let snap1 = snapshots[i-1]
                let snap2 = snapshots[i]
                
                let t1 = snap1.timestamp.timeIntervalSince1970
                let t2 = snap2.timestamp.timeIntervalSince1970
                let dtMin = max(0.5, (t2 - t1) / 60.0)
                
                let views1 = Double(snap1.views)
                let views2 = Double(snap2.views)
                let shares1 = Double(snap1.shares)
                let shares2 = Double(snap2.shares)
                
                let vpm = max(0, (views2 - views1) / dtMin)
                let spm = max(0, (shares2 - shares1) / dtMin)
                let epr = Double(snap2.likes + snap2.comments + snap2.shares) / max(views2, 1.0)
                let acc = vpm - prevVpm
                
                let ageMin = snap2.timestamp.timeIntervalSince(snap2.createdAt) / 60.0
                let bucket = TimeBucket.bucket(forAgeMinutes: ageMin)
                
                bucketDataVPM[bucket]?.append(vpm)
                bucketDataEPR[bucket]?.append(epr)
                bucketDataSPM[bucket]?.append(spm)
                bucketDataACC[bucket]?.append(acc)
                
                prevVpm = vpm
            }
        }
        
        var result: [TimeBucket: BaselineBucket] = [:]
        
        for bucket in TimeBucket.allCases {
            let vpms = bucketDataVPM[bucket] ?? []
            let eprs = bucketDataEPR[bucket] ?? []
            let spms = bucketDataSPM[bucket] ?? []
            let accs = bucketDataACC[bucket] ?? []
            
            if vpms.isEmpty {
                // Empty bucket fallback
                result[bucket] = BaselineBucket(
                    bucket: bucket,
                    medianVPM: 0.0, iqrVPM: RobustStats.epsilon,
                    medianEPR: 0.0, iqrEPR: RobustStats.epsilon,
                    medianSPM: 0.0, iqrSPM: RobustStats.epsilon,
                    medianACC: 0.0, iqrACC: RobustStats.epsilon,
                    sampleSize: 0
                )
            } else {
                result[bucket] = BaselineBucket(
                    bucket: bucket,
                    medianVPM: RobustStats.median(in: vpms),
                    iqrVPM: RobustStats.iqr(in: vpms),
                    medianEPR: RobustStats.median(in: eprs),
                    iqrEPR: RobustStats.iqr(in: eprs),
                    medianSPM: RobustStats.median(in: spms),
                    iqrSPM: RobustStats.iqr(in: spms),
                    medianACC: RobustStats.median(in: accs),
                    iqrACC: RobustStats.iqr(in: accs),
                    sampleSize: validPostsCount // Use valid posts count for confidence
                )
            }
        }
        
        return result
    }
}

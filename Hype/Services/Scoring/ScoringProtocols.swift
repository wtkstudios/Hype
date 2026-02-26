import Foundation

// B) PERSISTENCE CONTRACTS

protocol SnapshotStore {
    func saveSnapshots(_ snapshots: [VideoSnapshot]) async throws
    func fetchSnapshots(videoId: String, since: Date?) async throws -> [VideoSnapshot]
    func fetchRecentVideoIds(limit: Int) async throws -> [String]
    func fetchLatestSnapshot(videoId: String) async throws -> VideoSnapshot?
}

protocol BaselineStore {
    func saveBaseline(accountId: String, buckets: [TimeBucket: BaselineBucket]) async throws
    func fetchBaseline(accountId: String) async throws -> [TimeBucket: BaselineBucket]?
}

protocol ScoreStore {
    func saveHype(accountId: String, videoId: String, computation: HypeComputation) async throws
    func fetchRecentHypes(accountId: String, limit: Int) async throws -> [(videoId: String, createdAt: Date, hype: Int)]
}

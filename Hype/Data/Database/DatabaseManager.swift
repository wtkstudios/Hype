import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    var dbPool: DatabasePool!
    
    private init() {
        do {
            try setupDatabase()
        } catch {
            print("Failed to setup database: \(error)")
        }
    }
    
    private func setupDatabase() throws {
        let databaseURL = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("hype.sqlite")
        
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { print($0) }
        }
        
        dbPool = try DatabasePool(path: databaseURL.path, configuration: config)
        
        try migrator.migrate(dbPool)
    }
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { db in
            try db.create(table: "userAccount") { t in
                t.column("id", .text).primaryKey()
                t.column("tiktokUserId", .text).notNull()
                t.column("displayName", .text)
                t.column("handle", .text)
                t.column("profileImageURL", .text)
                t.column("connectedAt", .datetime)
                t.column("lastSyncAt", .datetime)
                t.column("scopesGranted", .text)
                t.column("accountType", .text)
                t.column("isActive", .boolean).notNull().defaults(to: true)
            }
            
            try db.create(table: "video") { t in
                t.column("id", .text).primaryKey()
                t.column("accountId", .text).notNull().references("userAccount", onDelete: .cascade)
                t.column("createdAt", .datetime).notNull()
                t.column("caption", .text)
                t.column("durationSeconds", .integer)
                t.column("thumbnailURL", .text)
                t.column("permalinkURL", .text)
                t.column("isPinned", .boolean).notNull().defaults(to: false)
                t.column("isDeleted", .boolean).notNull().defaults(to: false)
                t.column("lastMetricsAt", .datetime)
            }
            
            try db.create(table: "videoMetricsSnapshot") { t in
                t.column("id", .text).primaryKey()
                t.column("videoId", .text).notNull().references("video", onDelete: .cascade)
                t.column("capturedAt", .datetime).notNull()
                t.column("views", .integer).notNull()
                t.column("likes", .integer).notNull()
                t.column("comments", .integer).notNull()
                t.column("shares", .integer).notNull()
                t.column("saves", .integer).notNull()
            }
            
            try db.create(table: "baselineProfile") { t in
                t.column("id", .text).primaryKey()
                t.column("accountId", .text).notNull().references("userAccount", onDelete: .cascade)
                t.column("computedAt", .datetime).notNull()
                t.column("windowDays", .integer).notNull()
                t.column("medianViews_15m", .integer)
                t.column("medianViews_30m", .integer)
                t.column("medianViews_60m", .integer)
                t.column("medianViews_24h", .integer)
                t.column("volatilityIndex", .double)
            }
            
            try db.create(table: "hypeScoreSnapshot") { t in
                t.column("id", .text).primaryKey()
                t.column("videoId", .text).notNull().references("video", onDelete: .cascade)
                t.column("capturedAt", .datetime).notNull()
                t.column("hypeScore", .double).notNull()
                t.column("velocityScore", .double).notNull()
                t.column("deviationFromBaseline", .double).notNull()
                t.column("breakoutProbability", .double).notNull()
                t.column("phase", .text).notNull()
                t.column("recommendedAction", .text).notNull()
            }
        }
        
        return migrator
    }
    
    // MARK: - Core Operations
    
    func save(user: UserAccount) throws {
        try dbPool.write { db in
            try user.save(db)
        }
    }
    
    func save(videos: [Video]) throws {
        try dbPool.write { db in
            for video in videos {
                try video.save(db)
            }
        }
    }
    
    func save(snapshots: [VideoMetricsSnapshot]) throws {
        try dbPool.write { db in
            for snapshot in snapshots {
                try snapshot.save(db)
            }
        }
    }
    
    func fetchRecentVideos(for accountId: String, limit: Int = 20) throws -> [Video] {
        return try dbPool.read { db in
            try Video
                .filter(Column("accountId") == accountId)
                .order(Column("createdAt").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }
    
    // MARK: - Analytics Operations
    
    func save(baseline: BaselineProfile) throws {
        try dbPool.write { db in
            try baseline.save(db)
        }
    }
    
    func fetchBaseline(for accountId: String) throws -> BaselineProfile? {
        return try dbPool.read { db in
            try BaselineProfile
                .filter(Column("accountId") == accountId)
                .order(Column("computedAt").desc)
                .fetchOne(db)
        }
    }
    
    func save(score: HypeScoreSnapshot) throws {
        try dbPool.write { db in
            try score.save(db)
        }
    }
    
    func fetchLatestScore(for videoId: String) throws -> HypeScoreSnapshot? {
        return try dbPool.read { db in
            try HypeScoreSnapshot
                .filter(Column("videoId") == videoId)
                .order(Column("capturedAt").desc)
                .fetchOne(db)
        }
    }
}

import Foundation
import GRDB

struct UserAccount: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var tiktokUserId: String
    var displayName: String?
    var handle: String?
    var profileImageURL: String?
    var connectedAt: Date
    var lastSyncAt: Date?
    var scopesGranted: String?
    var accountType: String?
    var followerCount: Int?
    var totalLikes: Int?
    var totalComments: Int?
    var isActive: Bool = true
}

struct Video: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var accountId: String
    var createdAt: Date
    var caption: String?
    var durationSeconds: Int?
    var thumbnailURL: String?
    var permalinkURL: String?
    var isPinned: Bool = false
    var isDeleted: Bool = false
    var lastMetricsAt: Date?
}

struct VideoMetricsSnapshot: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var videoId: String
    var capturedAt: Date
    var views: Int
    var likes: Int
    var comments: Int
    var shares: Int
    var saves: Int
}

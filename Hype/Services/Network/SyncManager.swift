import Foundation

class SyncManager {
    static let shared = SyncManager()

    func performFullSync(for userId: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            print("Offline mode: Skipping network sync for \(userId).")
            return
        }
        
        // 1. Fetch Profile
        let profile = try await TikTokAPIService.shared.fetchUserProfile(userId: userId)
        
        // Convert DTO to Model
        var account = UserAccount(
            id: UUID().uuidString,
            tiktokUserId: profile.open_id,
            displayName: profile.display_name,
            handle: profile.display_name, // Typically handled from display name or omitted if strict
            profileImageURL: profile.avatar_url,
            connectedAt: Date(),
            lastSyncAt: Date(),
            scopesGranted: "user.info.basic,video.list",
            accountType: "creator",
            followerCount: profile.follower_count,
            totalLikes: profile.likes_count,
            totalComments: 0, // Will be calculated after fetching videos
            isActive: true
        )
        // Note: Intentionally deferring DB save until calculating totalComments

        
        // 2. Fetch Videos
        let videosDTO = try await TikTokAPIService.shared.fetchRecentVideos(userId: userId)
        
        var parsedVideos: [Video] = []
        var parsedSnapshots: [VideoMetricsSnapshot] = []
        let now = Date()
        
        for v in videosDTO {
            let video = Video(
                id: v.id,
                accountId: account.id,
                createdAt: Date(timeIntervalSince1970: TimeInterval(v.create_time)),
                caption: v.video_description,
                durationSeconds: v.duration,
                thumbnailURL: v.cover_image_url,
                permalinkURL: v.share_url,
                lastMetricsAt: now
            )
            parsedVideos.append(video)
            
            let snapshot = VideoMetricsSnapshot(
                id: UUID().uuidString,
                videoId: v.id,
                capturedAt: now,
                views: v.view_count ?? 0,
                likes: v.like_count ?? 0,
                comments: v.comment_count ?? 0,
                shares: v.share_count ?? 0,
                saves: 0 // Mocking saves if unavailable
            )
            parsedSnapshots.append(snapshot)
        }
        
        // Calculate missing info
        let calculatedComments = parsedSnapshots.reduce(0) { $0 + $1.comments }
        account.totalComments = calculatedComments
        if account.totalLikes == nil {
            account.totalLikes = parsedSnapshots.reduce(0) { $0 + $1.likes }
        }
        
        // Save Everything
        try DatabaseManager.shared.save(user: account)
        try DatabaseManager.shared.save(videos: parsedVideos)
        try DatabaseManager.shared.save(snapshots: parsedSnapshots)
        
        // Account Daily Snapshot Generation
        // This calculates whether we need to store a new point on the Account Dashboard trends sparkline
        let newSnapshot = AccountDailySnapshot(
            date: now,
            followerCount: account.followerCount ?? 0,
            totalLikes: account.totalLikes ?? 0,
            totalCommentsComputed: calculatedComments,
            momentumIndex: 92, // Mocking or pulling from an engine
            volatility: 1.15
        )
        // In a real database we'd do: try DatabaseManager.shared.save(accountSnapshot: newSnapshot)
        // For now, print to verify data pipeline integration.
        print("Generated Daily Snapshot for \(newSnapshot.dateString) with \(newSnapshot.followerCount) followers.")
        
        print("Successfully synced profile, \(parsedVideos.count) videos, and snapshots.")
    }
}

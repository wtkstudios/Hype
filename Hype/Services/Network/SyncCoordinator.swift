import Foundation

/// Coordinates data synchronization by setting adaptive polling intervals based on a video's lifecycle
/// age to optimize API limits and battery life, rather than polling uniformly.
class SyncCoordinator {
    static let shared = SyncCoordinator()
    
    // Defines how often to poll based on video age
    enum PollingTier {
        case critical   // Under 2 hours old: sync every 5 minutes
        case active     // Under 24 hours old: sync every 30 minutes
        case baseline   // Under 7 days old: sync every 4 hours
        case dormant    // Over 7 days old: sync once daily
        
        var intervalSeconds: TimeInterval {
            switch self {
            case .critical: return 300
            case .active: return 1800
            case .baseline: return 14400
            case .dormant: return 86400
            }
        }
    }
    
    private init() {}
    
    func determineTier(for videoCreatedAt: Date) -> PollingTier {
        let ageHours = Date().timeIntervalSince(videoCreatedAt) / 3600
        
        if ageHours < 2 {
            return .critical
        } else if ageHours < 24 {
            return .active
        } else if ageHours < 168 { // 7 days
            return .baseline
        } else {
            return .dormant
        }
    }
    
    /// Throws Domain Errors when Rate Limits or Auth exceptions are met
    func executeSync(for video: Video) async throws {
        let tier = determineTier(for: video.createdAt)
        
        // MVP: Adaptive Logging check
        print("[SyncCoordinator] Video \(video.id) is in \(tier) tier. Next sync window in \(tier.intervalSeconds)s")
        
        do {
            // Mocking network call
            // let metrics = try await APIClient.shared.fetchVideoData(...)
            // return metrics
            
            // Simulating rate limit hit randomly for demo
            if Int.random(in: 1...100) > 95 {
                 throw SyncError.rateLimitExceeded(retryAfterSeconds: 3600)
            }
            
        } catch {
             // Handle HTTP 429
             throw error
        }
    }
}

enum SyncError: Error, LocalizedError {
    case rateLimitExceeded(retryAfterSeconds: Int)
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded(let seconds):
            return "TikTok API Rate Limit reached. Throttling for \(seconds / 60)m."
        case .tokenExpired:
            return "TikTok session expired. Please reconnect."
        }
    }
}

import Foundation

enum TikTokAPIError: Error {
    case notAuthenticated
    case invalidResponse
    case apiError(String)
}

class TikTokAPIService {
    static let shared = TikTokAPIService()
    
    // We would inject this via Auth manager or similar, assuming a connected user UUID
    private func getToken(for userId: String) throws -> String {
        guard let token = try KeychainManager.shared.retrieve(for: userId) else {
            throw TikTokAPIError.notAuthenticated
        }
        return token
    }
    
    // https://developers.tiktok.com/doc/tiktok-api-v2-get-user-info/
    func fetchUserProfile(userId: String) async throws -> TikTokUserDTO {
        let token = try getToken(for: userId)
        let fields = "open_id,union_id,avatar_url,display_name,follower_count,likes_count"
        let endpoint = "/user/info/?fields=\(fields)"
        
        // This expects a TikTokResponse<TikTokUserDTO> wrapper based on TikTok docs
        let response: TikTokResponse<TikTokUserDTO> = try await APIClient.shared.request(
            endpoint: endpoint,
            token: token
        )
        
        if let error = response.error {
            throw TikTokAPIError.apiError(error.message)
        }
        
        return response.data
    }
    
    // https://developers.tiktok.com/doc/tiktok-api-v2-video-list/
    func fetchRecentVideos(userId: String, cursor: Int? = nil, maxCount: Int = 20) async throws -> [TikTokVideoDTO] {
        let token = try getToken(for: userId)
        let fields = "id,create_time,cover_image_url,share_url,video_description,duration,view_count,like_count,comment_count,share_count"
        
        var bodyParams: [String: Any] = [
            "max_count": maxCount
        ]
        
        if let cursor = cursor {
            bodyParams["cursor"] = cursor
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: bodyParams, options: [])
        
        // Note: The Video List API uses POST
        let response: TikTokResponse<[TikTokVideoDTO]> = try await APIClient.shared.request(
            endpoint: "/video/list/?fields=\(fields)",
            method: "POST",
            body: jsonData,
            token: token
        )
        
        if let error = response.error {
            throw TikTokAPIError.apiError(error.message)
        }
        
        return response.data
    }
}

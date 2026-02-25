import Foundation

// These are basic DTOs for the TikTok Display API endpoints
struct TikTokUserDTO: Decodable {
    let open_id: String
    let union_id: String?
    let display_name: String
    let avatar_url: String?
    let follower_count: Int?
    let likes_count: Int?
    // the payload is usually nested in 'data'
}

struct TikTokVideoDTO: Decodable {
    let id: String
    let create_time: Int
    let cover_image_url: String?
    let share_url: String?
    let video_description: String?
    let duration: Int?
    let view_count: Int? // Typically, metrics are separated or requested via specific scopes
    let like_count: Int?
    let comment_count: Int?
    let share_count: Int?
}

struct TikTokResponse<T: Decodable>: Decodable {
    let data: T
    let error: TikTokError?
}

struct TikTokError: Decodable {
    let code: String
    let message: String
}

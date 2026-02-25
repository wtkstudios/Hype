import Foundation

struct Constants {
    struct Keychain {
        static let service = "com.hype.app.keychain"
        static let accessTokenKey = "tiktok_access_token"
        static let refreshTokenKey = "tiktok_refresh_token"
    }
    
    struct API {
        static let baseURL = "https://open.tiktokapis.com/v2"
    }
}

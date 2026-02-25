import Foundation

struct AccountDailySnapshot: Codable, Identifiable {
    var id: UUID = UUID()
    let date: Date
    let followerCount: Int
    let totalLikes: Int
    let totalCommentsComputed: Int
    let momentumIndex: Int
    let volatility: Double
    
    // Helper to get start of day for easy comparison
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

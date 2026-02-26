import Foundation

// H) OVERALL (ACCOUNT OUT OF 100)

class AccountOverallEngine {
    
    func computeOverall(
        recentPosts: [(createdAt: Date, hype: Int)],
        now: Date
    ) -> AccountOverallComputation {
        
        guard !recentPosts.isEmpty else {
            return AccountOverallComputation(overallScore: 0, stability: .low, volatilityStd: 0.0)
        }
        
        // 1) take up to last 10 posts (most recent first)
        let top10 = recentPosts.sorted(by: { $0.createdAt > $1.createdAt }).prefix(10)
        
        var weightedSum = 0.0
        var totalWeight = 0.0
        var hypesForStd: [Double] = []
        
        for post in top10 {
            // 2) weight each post
            let ageDays = max(0, now.timeIntervalSince(post.createdAt) / 86400.0)
            let w = exp(-ageDays / 7.0) // 7-day half-life
            
            let hypeDouble = Double(post.hype)
            weightedSum += hypeDouble * w
            totalWeight += w
            hypesForStd.append(hypeDouble)
        }
        
        // 3) overallRaw
        let overallRaw = totalWeight > 0 ? (weightedSum / totalWeight) : 0.0
        
        // 4) overallScore
        let overallScore = RobustStats.clamp(Int(round(overallRaw)), 0, 100)
        
        // Volatility/std
        let meanHype = hypesForStd.reduce(0, +) / Double(hypesForStd.count)
        let sumSquaredDiff = hypesForStd.reduce(0.0) { $0 + pow($1 - meanHype, 2) }
        let stdDev = hypesForStd.count > 1 ? sqrt(sumSquaredDiff / Double(hypesForStd.count)) : 0.0
        
        let stability: StabilityLabel
        if stdDev < 10.0 {
            stability = .low
        } else if stdDev <= 20.0 {
            stability = .moderate
        } else {
            stability = .high
        }
        
        return AccountOverallComputation(
            overallScore: overallScore,
            stability: stability,
            volatilityStd: stdDev
        )
    }
}

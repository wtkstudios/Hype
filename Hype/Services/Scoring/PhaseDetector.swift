import Foundation

// G) PHASE DETECTOR

class PhaseDetector {
    
    static func phase(
        hypeScore: Int,
        previousHypes: [Int],
        postAgeMinutes: Double
    ) -> PostPhase {
        
        // Calculate slope based on most recent previous hypes
        let avgPrevious: Double = previousHypes.isEmpty ? Double(hypeScore) : (previousHypes.map { Double($0) }.reduce(0, +) / Double(previousHypes.count))
        let slope = Double(hypeScore) - avgPrevious
        
        // Rules
        if postAgeMinutes > 360, slope >= 4.0, previousHypes.contains(where: { $0 < 50 }), hypeScore > 60 {
            return .reignite
        }
        
        if postAgeMinutes > 45, slope >= 4.0, hypeScore >= 65 {
            return .breakout
        }
        
        if abs(slope) < 2.0, hypeScore >= 45, hypeScore <= 70, postAgeMinutes >= 20 {
            // Only plateau if age indicates it's had time to settle
            return .plateau
        }
        
        if hypeScore >= 60, (slope >= 2.0 || previousHypes.isEmpty) {
            return .expanding
        }
        
        if postAgeMinutes < 20, hypeScore < 55 {
            return .testing
        }
        
        // Default fallbacks
        if hypeScore >= 60 {
            return .expanding
        } else if postAgeMinutes >= 60 {
            return .plateau
        } else {
            return .testing
        }
    }
}

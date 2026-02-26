import Foundation

// D) TIME BUCKETING

extension TimeBucket {
    static func bucket(forAgeMinutes age: Double) -> TimeBucket {
        switch age {
        case 0..<15:
            return .min0_15
        case 15..<30:
            return .min15_30
        case 30..<60:
            return .min30_60
        case 60..<120:
            return .hr1_2
        case 120..<360:
            return .hr2_6
        case 360..<1440:
            return .hr6_24
        default:
            return .day1_7
        }
    }
}

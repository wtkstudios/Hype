import Foundation

// C) UTILITIES (ROBUST STATS)

enum RobustStats {
    static let epsilon: Double = 1e-4

    static func clamp<T: Comparable>(_ value: T, _ minValue: T, _ maxValue: T) -> T {
        return min(max(value, minValue), maxValue)
    }

    static func percentile(p: Double, in array: [Double]) -> Double {
        guard !array.isEmpty else { return 0.0 }
        let sorted = array.sorted()
        let k = (Double(sorted.count - 1) * p)
        let f = floor(k)
        let c = ceil(k)
        if f == c {
            return sorted[Int(k)]
        }
        let d0 = sorted[Int(f)] * (c - k)
        let d1 = sorted[Int(c)] * (k - f)
        return d0 + d1
    }

    static func median(in array: [Double]) -> Double {
        return percentile(p: 0.5, in: array)
    }

    static func iqr(in array: [Double]) -> Double {
        guard array.count > 1 else { return 0.0 }
        let q1 = percentile(p: 0.25, in: array)
        let q3 = percentile(p: 0.75, in: array)
        return q3 - q1
    }

    static func robustZScore(value: Double, median: Double, iqr: Double) -> Double {
        return (value - median) / max(iqr, epsilon)
    }

    static func sigmoid(_ x: Double) -> Double {
        return 1.0 / (1.0 + exp(-x))
    }
}

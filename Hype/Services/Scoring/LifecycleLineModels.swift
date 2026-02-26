import Foundation
import CoreGraphics // For CGPoint if needed in UI later

// Represents a single point in the lifecycle graph
struct LifecyclePoint {
    let t: Date
    let ageMin: Double
    let vpm: Double
    let phase: PostPhase
}

// Represents a continuous segment of time within the same phase
struct PhaseRunSegment: Identifiable {
    let id = UUID()
    let phase: PostPhase
    let startAgeMin: Double
    let endAgeMin: Double
    let durationMin: Double
    let points: [LifecyclePoint]
    let runIndex: Int
}

// The entire timeline model for the Lifecycle Line chart
struct LifecycleLineModel {
    let segments: [PhaseRunSegment]
    let activePhase: PostPhase
    let activeAgeMin: Double
    let confidence01: Double
    let projectedNextPhase: PostPhase?
    let projectedProb01: Double?
    let projectedEndAgeMin: Double?   // For Dashed preview curve extents
    let projectedPoints: [CGPoint]?   // Pre-calculated projection UI coordinates (optional depending on builder)
    let inflectionPoints: [LifecyclePoint] // Rare event markers (max 2)
}

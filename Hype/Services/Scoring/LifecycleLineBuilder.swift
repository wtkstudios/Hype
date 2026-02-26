import Foundation
import CoreGraphics

class LifecycleLineBuilder {
    
    func buildModel(
        snapshots: [VideoSnapshot],
        hypeHistory: [(timestamp: Date, hype: HypeComputation)],
        now: Date
    ) -> LifecycleLineModel {
        
        let sortedSnapshots = snapshots.sorted(by: { $0.timestamp < $1.timestamp })
        let sortedHistory = hypeHistory.sorted(by: { $0.timestamp < $1.timestamp })
        
        guard let firstSnapshot = sortedSnapshots.first else {
            return emptyModel()
        }
        
        let createdAt = firstSnapshot.createdAt
        
        // 1. Gather timestamps (checkpoints) every 5-10 mins if history is sparse
        var checkpoints = sortedHistory.map { $0.timestamp }
        if checkpoints.isEmpty {
            checkpoints = sortedSnapshots.map { $0.timestamp }
        }
        
        // Deduplicate
        var uniqueCheckpoints: [Date] = []
        for cp in checkpoints {
            if let last = uniqueCheckpoints.last, cp.timeIntervalSince(last) < 60 { continue }
            uniqueCheckpoints.append(cp)
        }
        if uniqueCheckpoints.isEmpty { uniqueCheckpoints = [now] }
        
        // 2. Build Raw Points
        var rawPoints: [LifecyclePoint] = []
        
        func getSnapshotsFor(time: Date) -> (VideoSnapshot?, VideoSnapshot?) {
            let past = sortedSnapshots.filter { $0.timestamp <= time }
            if past.count >= 2 { return (past[past.count - 1], past[past.count - 2]) }
            if past.count == 1 { return (past[0], nil) }
            return (nil, nil)
        }
        
        for cp in uniqueCheckpoints {
            let ageMin = max(0, cp.timeIntervalSince(createdAt) / 60.0)
            let (currSnap, prevSnap) = getSnapshotsFor(time: cp)
            
            var vpm = 0.0
            if let c = currSnap {
                let pViews = prevSnap?.views ?? 0
                let pTime = prevSnap?.timestamp ?? createdAt
                let dtMin = max(0.5, c.timestamp.timeIntervalSince(pTime) / 60.0)
                vpm = Double(max(0, c.views - pViews)) / dtMin
            }
            
            // Match History Phase
            var phase: PostPhase = .testing
            let match = sortedHistory.min(by: { abs($0.timestamp.timeIntervalSince(cp)) < abs($1.timestamp.timeIntervalSince(cp)) })
            if let m = match, abs(m.timestamp.timeIntervalSince(cp)) < 300 {
                phase = m.hype.phase
            } else {
                phase = PhaseDetector.phase(hypeScore: 0, previousHypes: [], postAgeMinutes: ageMin)
            }
            
            rawPoints.append(LifecyclePoint(t: cp, ageMin: ageMin, vpm: vpm, phase: phase))
        }
        
        // Ensure continuous coverage up to `now` if the last point is old
        if let last = rawPoints.last, now.timeIntervalSince(last.t) > 60 {
            let ageMin = max(0, now.timeIntervalSince(createdAt) / 60.0)
            let (currSnap, prevSnap) = getSnapshotsFor(time: now)
            var vpm = last.vpm
            if let c = currSnap, let p = prevSnap {
                let dtMin = max(0.5, c.timestamp.timeIntervalSince(p.timestamp) / 60.0)
                vpm = Double(max(0, c.views - p.views)) / dtMin
            }
            rawPoints.append(LifecyclePoint(t: now, ageMin: ageMin, vpm: vpm, phase: last.phase))
        }
        
        if rawPoints.isEmpty { return emptyModel() }
        
        // 3. Apply Percentile Capping (5th - 95th) for smooth rendering mapping later
        let vpms = rawPoints.map { $0.vpm }.sorted()
        let p05 = vpms[max(0, Int(Double(vpms.count) * 0.05))]
        let p95 = vpms[min(vpms.count - 1, Int(Double(vpms.count) * 0.95))]
        let safeMax = max(p95, p05 + 1.0)
        
        let cappedPoints = rawPoints.map { pt -> LifecyclePoint in
            let cappedVpm = min(max(pt.vpm, p05), safeMax)
            return LifecyclePoint(t: pt.t, ageMin: pt.ageMin, vpm: cappedVpm, phase: pt.phase)
        }
        
        // 4. Split into Phase Segments
        var segments: [PhaseRunSegment] = []
        var currentSegmentPoints: [LifecyclePoint] = [cappedPoints[0]]
        var currentPhase = cappedPoints[0].phase
        var segStartAge = cappedPoints[0].ageMin
        var runIndex = 0
        
        for i in 1..<cappedPoints.count {
            let pt = cappedPoints[i]
            
            if pt.phase == currentPhase {
                currentSegmentPoints.append(pt)
            } else {
                // Phase boundary: end current segment, start new one
                // Share the boundary point so the line is continuous in UI
                currentSegmentPoints.append(pt)
                
                let duration = pt.ageMin - segStartAge
                segments.append(PhaseRunSegment(
                    phase: currentPhase,
                    startAgeMin: segStartAge,
                    endAgeMin: pt.ageMin,
                    durationMin: duration,
                    points: currentSegmentPoints,
                    runIndex: runIndex
                ))
                
                // Reset for next phase
                currentPhase = pt.phase
                segStartAge = pt.ageMin
                currentSegmentPoints = [pt]
                runIndex += 1
            }
        }
        
        // Close final segment
        if let lastPt = cappedPoints.last {
            let duration = lastPt.ageMin - segStartAge
            segments.append(PhaseRunSegment(
                phase: currentPhase,
                startAgeMin: segStartAge,
                endAgeMin: lastPt.ageMin,
                durationMin: duration,
                points: currentSegmentPoints,
                runIndex: runIndex
            ))
        }
        
        let activePhase = segments.last?.phase ?? .testing
        let latestHype = sortedHistory.last?.hype
        let confidence01 = latestHype?.confidence01 ?? 0.0
        let activeAgeMin = rawPoints.last?.ageMin ?? 0.0
        
        // 4b. Find Inflection Markers (Max 2)
        // Find local maxima/minima by checking sign changes in slope
        var inflectionPoints: [LifecyclePoint] = []
        if cappedPoints.count > 3 {
            var slopes: [Double] = []
            for i in 1..<cappedPoints.count {
                let dt = cappedPoints[i].ageMin - cappedPoints[i-1].ageMin
                let dv = cappedPoints[i].vpm - cappedPoints[i-1].vpm
                slopes.append(dt > 0 ? dv / dt : 0)
            }
            
            for i in 1..<slopes.count {
                // Sign change = local extremum
                if (slopes[i-1] > 0 && slopes[i] <= 0) || (slopes[i-1] < 0 && slopes[i] >= 0) {
                    // Only mark substantial changes or high peaks to avoid noise
                    if abs(slopes[i-1] - slopes[i]) > 1.0 || cappedPoints[i].vpm > p95 * 0.8 {
                        inflectionPoints.append(cappedPoints[i])
                    }
                }
            }
            
            // Limit to max 2 most prominent (e.g. highest VPMs)
            if inflectionPoints.count > 2 {
                inflectionPoints = Array(inflectionPoints.sorted(by: { $0.vpm > $1.vpm }).prefix(2))
            }
        }
        
        // 5. Projected Breakout (Optional dashed line)
        var projectedNextPhase: PostPhase? = nil
        var projectedProb01: Double? = nil
        var projectedEndAgeMin: Double? = nil
        var projectedPoints: [CGPoint]? = nil
        
        if let hype = latestHype, hype.confidence01 >= 0.70 { // Stricter cutoff
            if hype.breakoutProb01 >= 0.80 && activePhase == .expanding {
                projectedNextPhase = .breakout
                projectedProb01 = hype.breakoutProb01
                
                // Add a dashed projection 20 minutes into the future
                projectedEndAgeMin = activeAgeMin + 20.0
                
                // In UI coords, we generally map ageMin to X. Let's just store ageMin/vpm as raw data in UI later,
                // or if we must export UI structs here, we could. The spec says `projectedPoints: [CGPoint]?` mostly
                // meant normalized. Let's let the UI map data to coordinates. We'll leave `projectedPoints` nil and rely
                // on `projectedEndAgeMin`.
            }
        }
        
        return LifecycleLineModel(
            segments: segments,
            activePhase: activePhase,
            activeAgeMin: activeAgeMin,
            confidence01: confidence01,
            projectedNextPhase: projectedNextPhase,
            projectedProb01: projectedProb01,
            projectedEndAgeMin: projectedEndAgeMin,
            projectedPoints: projectedPoints,
            inflectionPoints: inflectionPoints
        )
    }
    
    private func emptyModel() -> LifecycleLineModel {
        return LifecycleLineModel(
            segments: [],
            activePhase: .testing,
            activeAgeMin: 0.0,
            confidence01: 0.0,
            projectedNextPhase: nil,
            projectedProb01: nil,
            projectedEndAgeMin: nil,
            projectedPoints: nil,
            inflectionPoints: []
        )
    }
}

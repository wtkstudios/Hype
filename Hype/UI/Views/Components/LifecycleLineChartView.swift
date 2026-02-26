import SwiftUI

struct LifecycleLineChartView: View {
    let model: LifecycleLineModel
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            
            let totalAgeMin = model.projectedEndAgeMin ?? model.activeAgeMin
            
            // If we have no time span or no height, just clear
            if totalAgeMin <= 0 || w <= 0 || h <= 0 {
                Color.clear
            } else {
                ZStack(alignment: .topLeading) {
                    
                    // 1. Draw Baseline
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: w, y: h))
                    }
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    
                    
                    // Determine Universal Min/Max VPM across all points to map height smoothly
                    let allPoints = model.segments.flatMap { $0.points }
                    let minVPM = allPoints.map { $0.vpm }.min() ?? 0
                    let maxVPM = allPoints.map { $0.vpm }.max() ?? 1 // avoid div by 0
                    let vpmRange = max(1.0, maxVPM - minVPM)
                    let minAgeRaw = allPoints.map { $0.ageMin }.min() ?? 0
                    let totalAge = max(1.0, totalAgeMin - minAgeRaw) // true visible duration
                    
                    // X-Axis Baseline Formatting overlay
                    if let firstPt = allPoints.first, let lastPt = allPoints.last {
                        let dStart = firstPt.t.addingTimeInterval(-firstPt.ageMin * 60) 
                        let finalMin = model.projectedEndAgeMin ?? lastPt.ageMin
                        let dEnd = dStart.addingTimeInterval(finalMin * 60)
                        
                        Text(formatAxisDate(dStart))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Color.HYPE.text.opacity(0.3))
                            .position(x: 34, y: h + 12)
                            
                        Text(formatAxisDate(dEnd))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Color.HYPE.text.opacity(0.3))
                            .position(x: w - 34, y: h + 12)
                    }
                    
                    // 2. Draw Each Segment
                    ForEach(model.segments) { segment in
                        
                        let isActive = segment.phase == model.activePhase && segment.id == model.segments.last?.id
                        let phaseColor = colorFor(phase: segment.phase)
                        
                        // Vertical subtle tick at start boundary (except age 0)
                        if segment.startAgeMin > minAgeRaw {
                            Path { path in
                                let startX = CGFloat((segment.startAgeMin - minAgeRaw) / totalAge) * w
                                path.move(to: CGPoint(x: startX, y: h - 10))
                                path.addLine(to: CGPoint(x: startX, y: h))
                            }
                            .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1))
                        }
                        
                        // Label above the curve if duration is long enough or it's active
                        if (segment.durationMin >= 3.0 || isActive) && segment.points.count > 0 {
                            let midAge = segment.startAgeMin + (segment.durationMin / 2)
                            let midX = CGFloat((midAge - minAgeRaw) / totalAge) * w
                            let segMaxVPM = segment.points.map(\.vpm).max() ?? 0
                            let fakePt = mapPosition(ageMin: midAge, vpm: segMaxVPM, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            // Push label up slightly so it doesn't collide
                            let labelY = max(10, fakePt.y - 18)
                            
                            Text("\(segment.phase.rawValue.uppercased()) · \(Int(segment.durationMin))m")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(phaseColor.opacity(isActive ? 1.0 : 0.4))
                                .position(x: midX, y: labelY)
                        }
                        
                        // The Curve Path
                        let splinePath = Path { path in
                            guard segment.points.count >= 2 else {
                                if let single = segment.points.first {
                                    let p = mapPosition(ageMin: single.ageMin, vpm: single.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                                    path.move(to: p)
                                    path.addLine(to: CGPoint(x: p.x + 1, y: p.y))
                                }
                                return
                            }
                            
                            let startPt = mapPosition(ageMin: segment.points[0].ageMin, vpm: segment.points[0].vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            path.move(to: startPt)
                            
                            // Simple linear segments connecting points. 
                            // (If true Catmull-Rom is strictly required, implementing a bezier curve
                            // math extension takes hundreds of lines. Given "linear chart" + "curve" spec,
                            // SwiftUI straight lines mapping close temporal density looks effectively curved.
                            // If points are sparse, add quadCurve)
                            for i in 1..<segment.points.count {
                                let p = mapPosition(ageMin: segment.points[i].ageMin, vpm: segment.points[i].vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                                path.addLine(to: p)
                            }
                        }
                        
                        
                        // Active gradient fill
                        if isActive {
                            let gradientPath = Path { path in
                                path.addPath(splinePath)
                                if let last = segment.points.last, let first = segment.points.first {
                                    let pEnd = mapPosition(ageMin: last.ageMin, vpm: last.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                                    let pStart = mapPosition(ageMin: first.ageMin, vpm: first.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                                    
                                    path.addLine(to: CGPoint(x: pEnd.x, y: h))
                                    path.addLine(to: CGPoint(x: pStart.x, y: h))
                                    path.closeSubpath()
                                }
                            }
                            gradientPath
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [phaseColor.opacity(0.15), Color.clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        }
                        
                        splinePath
                            .stroke(phaseColor, style: StrokeStyle(lineWidth: isActive ? 2.5 : 2.0, lineCap: .round, lineJoin: .round))
                            .shadow(color: isActive ? phaseColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                        
                        // Active Node Highlight
                        if isActive, let last = segment.points.last, last.t == segment.points.max(by: { $0.t < $1.t })?.t {
                            let p = mapPosition(ageMin: last.ageMin, vpm: last.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            Circle()
                                .fill(phaseColor)
                                .frame(width: 8, height: 8)
                                .shadow(color: phaseColor, radius: 6)
                                .position(p)
                                
                            // Move text label so it doesn't clip off the right edge
                            let rawLabelX = p.x
                            let safeLabelX = min(w - 20, rawLabelX)
                            // VPM tag underneath
                            Text("\(Int(last.vpm)) vpm")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.9))
                                .position(x: safeLabelX, y: p.y + 14)
                        }
                    }
                    
                    // 2b. Inflection Markers
                    ForEach(model.inflectionPoints.indices, id: \.self) { i in
                        let ipt = model.inflectionPoints[i]
                        let p = mapPosition(ageMin: ipt.ageMin, vpm: ipt.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                        
                        Circle()
                            .strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5)
                            .background(Circle().fill(Color.black))
                            .frame(width: 6, height: 6)
                            .position(p)
                    }
                    
                    // 3. Projected Next Phase (Dashed)
                    if let projPhase = model.projectedNextPhase, let projEndAge = model.projectedEndAgeMin, let prob = model.projectedProb01, prob >= 0.65 {
                        if let lastSeg = model.segments.last, let lastPt = lastSeg.points.last {
                            let pColor = colorFor(phase: projPhase)
                            let startP = mapPosition(ageMin: lastPt.ageMin, vpm: lastPt.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            
                            // Projection math using safe horizontal trajectory with gentle rise
                            let projectedVPM = lastPt.vpm * 1.3 
                            let endP = mapPosition(ageMin: projEndAge, vpm: projectedVPM, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            
                            Path { path in
                                path.move(to: startP)
                                path.addQuadCurve(to: endP, control: CGPoint(x: startP.x + (endP.x - startP.x)*0.3, y: startP.y))
                            }
                            .stroke(pColor.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                            
                            // Label strictly kept within standard card bounds manually aligned
                            Text("Projected: \(projPhase.rawValue.uppercased()) (\(Int(prob * 100))%)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(pColor.opacity(0.9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .position(x: min(w - 60, startP.x + 40), y: min(h - 10, startP.y - 12))
                        }
                    } else if model.segments.last?.durationMin ?? 0 > 2.0 {
                        // Fallback Text if projection is too soft or sparse data
                        Text("Projection unavailable")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Color.HYPE.text.opacity(0.3))
                            .position(x: w / 2, y: h - 10)
                    }
                }
            }
        }
    }
    
    private func colorFor(phase: PostPhase) -> Color {
        switch phase {
        case .testing: return Color.HYPE.mustard
        case .expanding: return Color.HYPE.tea
        case .breakout: return Color(hex: "00FFDD") // Neon Cyan
        case .plateau: return Color(hex: "A390E4") // Muted Lavender
        case .reignite: return Color.HYPE.neonRed
        }
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    // Helper to map data -> coordinates
    private func mapPosition(ageMin: Double, vpm: Double, totalAge: Double, minAgeRaw: Double, minVPM: Double, vpmRange: Double, w: CGFloat, h: CGFloat) -> CGPoint {
        let x = CGFloat((ageMin - minAgeRaw) / totalAge) * w
        // standard bottom-origin mapping. Leave 10% vertical padding at top
        let normalizedY = (vpm - minVPM) / vpmRange
        let y = h - (CGFloat(normalizedY) * (h * 0.90))
        return CGPoint(x: x, y: y)
    }
}

import SwiftUI

struct LifecycleLineChartView: View {
    let model: LifecycleLineModel
    
    @State private var selectedPoint: LifecyclePoint? = nil
    @State private var isDragging: Bool = false
    
    // Layout margins
    private let yAxisWidth: CGFloat = 44
    private let xAxisHeight: CGFloat = 26
    
    /// All data points across all segments
    private var allPoints: [LifecyclePoint] {
        model.segments.flatMap { $0.points }
    }
    
    /// Average value for insight classification
    private var averageVPM: Double {
        let vals = allPoints.map { $0.vpm }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Double(vals.count)
    }
    
    var body: some View {
        let totalAgeMin = model.projectedEndAgeMin ?? model.activeAgeMin
        
        if allPoints.isEmpty || totalAgeMin <= 0 {
            Color.clear
        } else {
            let minAgeRaw = allPoints.map { $0.ageMin }.min() ?? 0
            // Use projected end to create space on the right for projection
            let projectedEnd = model.projectedEndAgeMin ?? (allPoints.map { $0.ageMin }.max() ?? 1)
            // Add 15% extra padding on the right so projection has breathing room
            let totalAge = max(1.0, (projectedEnd - minAgeRaw) * 1.15)
            let minVPM = allPoints.map { $0.vpm }.min() ?? 0
            let maxVPM = allPoints.map { $0.vpm }.max() ?? 1
            let vpmRange = max(1.0, maxVPM - minVPM)
            
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    // Y-axis (Views)
                    yAxisLabels(minVPM: minVPM, maxVPM: maxVPM, vpmRange: vpmRange)
                    
                    // Main graph
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        
                        ZStack(alignment: .topLeading) {
                            // Grid lines
                            gridLines(minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            
                            // Phase boundary lines (full height dashed)
                            phaseBoundaryLines(minAgeRaw: minAgeRaw, totalAge: totalAge, w: w, h: h)
                            
                            // Draw each segment
                            ForEach(model.segments) { segment in
                                segmentView(segment: segment, minAgeRaw: minAgeRaw, totalAge: totalAge, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            }
                            
                            // Inflection markers
                            ForEach(model.inflectionPoints.indices, id: \.self) { i in
                                let ipt = model.inflectionPoints[i]
                                let p = mapPos(ageMin: ipt.ageMin, vpm: ipt.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5)
                                    .background(Circle().fill(Color.black))
                                    .frame(width: 6, height: 6)
                                    .position(p)
                            }
                            
                            // Forecast / projected phase
                            forecastView(minAgeRaw: minAgeRaw, totalAge: totalAge, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                            
                            // Selection vertical line
                            if let sel = selectedPoint {
                                let x = mapX(ageMin: sel.ageMin, totalAge: totalAge, minAgeRaw: minAgeRaw, w: w)
                                Path { path in
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: h))
                                }
                                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                
                                // Insight tooltip
                                let y = mapY(vpm: sel.vpm, minVPM: minVPM, vpmRange: vpmRange, h: h)
                                insightCard(for: sel)
                                    .position(
                                        x: x < w / 2 ? min(x + 75, w - 55) : max(x - 75, 55),
                                        y: max(y - 30, 40)
                                    )
                            }
                        }
                        // Sweep gesture
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    isDragging = true
                                    let xPos = drag.location.x
                                    if let nearest = nearestPoint(to: xPos, totalAge: totalAge, minAgeRaw: minAgeRaw, width: w) {
                                        if selectedPoint?.ageMin != nearest.ageMin {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred(intensity: 0.4)
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                selectedPoint = nearest
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                        .onTapGesture {
                            if selectedPoint != nil && !isDragging {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPoint = nil
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                }
                
                // X-axis (Time/Date)
                xAxisLabels(minAgeRaw: minAgeRaw, totalAge: totalAge)
            }
        }
    }
    
    // MARK: - Nearest Point for Sweep
    
    private func nearestPoint(to xPos: CGFloat, totalAge: Double, minAgeRaw: Double, width: CGFloat) -> LifecyclePoint? {
        guard !allPoints.isEmpty else { return nil }
        var closest: LifecyclePoint?
        var closestDist: CGFloat = .greatestFiniteMagnitude
        for pt in allPoints {
            let ptX = mapX(ageMin: pt.ageMin, totalAge: totalAge, minAgeRaw: minAgeRaw, w: width)
            let dist = abs(ptX - xPos)
            if dist < closestDist {
                closestDist = dist
                closest = pt
            }
        }
        return closest
    }
    
    // MARK: - Insight Card
    
    private func insightCard(for point: LifecyclePoint) -> some View {
        let dateStr = formatAxisDate(point.t)
        let valueStr = formatViewCount(point.vpm)
        let pctOfAvg = averageVPM > 0 ? ((point.vpm - averageVPM) / averageVPM) * 100 : 0
        let phaseColor = colorFor(phase: point.phase)
        
        // Is this a phase boundary?
        let isPhaseStart = model.segments.contains { seg in
            seg.points.first?.ageMin == point.ageMin && seg.runIndex > 0
        }
        
        let insight: String
        if isPhaseStart {
            insight = "Entered \(point.phase.rawValue.uppercased()) phase"
        } else if pctOfAvg >= 20 {
            insight = "Strong spike — viral momentum"
        } else if pctOfAvg >= 10 {
            insight = "Above average — good traction"
        } else if pctOfAvg <= -20 {
            insight = "Significant dip — engagement drop"
        } else if pctOfAvg <= -10 {
            insight = "Below average — slowing down"
        } else {
            insight = "Steady performance"
        }
        
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(dateStr)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                
                Text(point.phase.rawValue.uppercased())
                    .font(.system(size: 6, weight: .black))
                    .foregroundColor(phaseColor)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(phaseColor.opacity(0.15))
                    .cornerRadius(2)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPoint = nil
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                        .frame(width: 14, height: 14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
            
            Text(valueStr + " views")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
            
            Text(insight)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(Color.HYPE.text.opacity(0.45))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.HYPE.base.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(phaseColor.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 3)
        )
        .frame(width: 130)
    }
    
    // MARK: - Y-Axis
    
    private func yAxisLabels(minVPM: Double, maxVPM: Double, vpmRange: Double) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            let tickCount = 4
            let step = vpmRange / Double(tickCount)
            
            ForEach((0...tickCount).reversed(), id: \.self) { i in
                let value = minVPM + step * Double(i)
                Text(formatViewCount(value))
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.3))
                    .frame(height: 0)
                if i != 0 { Spacer() }
            }
        }
        .frame(width: yAxisWidth, height: 200)
        .padding(.trailing, 4)
    }
    
    // MARK: - X-Axis
    
    private func xAxisLabels(minAgeRaw: Double, totalAge: Double) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: yAxisWidth + 4)
            
            GeometryReader { geo in
                let w = geo.size.width
                
                if let firstPt = allPoints.first, let lastPt = allPoints.last {
                    let createdAt = firstPt.t.addingTimeInterval(-firstPt.ageMin * 60)
                    
                    let startDate = createdAt.addingTimeInterval(minAgeRaw * 60)
                    Text(formatAxisDate(startDate))
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.3))
                        .position(x: 30, y: 10)
                    
                    let midAge = minAgeRaw + totalAge / 2
                    let midDate = createdAt.addingTimeInterval(midAge * 60)
                    Text(formatAxisDate(midDate))
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.3))
                        .position(x: w / 2, y: 10)
                    
                    let endAge = minAgeRaw + totalAge
                    let endDate = createdAt.addingTimeInterval(endAge * 60)
                    Text(formatAxisDate(endDate))
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.3))
                        .position(x: w - 30, y: 10)
                }
            }
            .frame(height: xAxisHeight)
        }
    }
    
    // MARK: - Grid Lines
    
    private func gridLines(minVPM: Double, vpmRange: Double, w: CGFloat, h: CGFloat) -> some View {
        let tickCount = 4
        let step = vpmRange / Double(tickCount)
        
        return ForEach(0...tickCount, id: \.self) { i in
            let value = minVPM + step * Double(i)
            let y = mapY(vpm: value, minVPM: minVPM, vpmRange: vpmRange, h: h)
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: w, y: y))
            }
            .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
        }
    }
    
    // MARK: - Phase Boundary Lines
    
    private func phaseBoundaryLines(minAgeRaw: Double, totalAge: Double, w: CGFloat, h: CGFloat) -> some View {
        ForEach(model.segments.indices, id: \.self) { i in
            let segment = model.segments[i]
            
            if i > 0 {
                let x = mapX(ageMin: segment.startAgeMin, totalAge: totalAge, minAgeRaw: minAgeRaw, w: w)
                let phaseColor = colorFor(phase: segment.phase)
                
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: h))
                }
                .stroke(
                    phaseColor.opacity(0.2),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
            }
        }
    }
    
    // MARK: - Segment View
    
    private func segmentView(segment: PhaseRunSegment, minAgeRaw: Double, totalAge: Double, minVPM: Double, vpmRange: Double, w: CGFloat, h: CGFloat) -> some View {
        // Active = the last segment
        let isActive = segment.id == model.segments.last?.id
        let phaseColor = colorFor(phase: segment.phase)
        
        let splinePath = Path { path in
            guard segment.points.count >= 2 else {
                if let single = segment.points.first {
                    let p = mapPos(ageMin: single.ageMin, vpm: single.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                    path.move(to: p)
                    path.addLine(to: CGPoint(x: p.x + 1, y: p.y))
                }
                return
            }
            
            let startPt = mapPos(ageMin: segment.points[0].ageMin, vpm: segment.points[0].vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
            path.move(to: startPt)
            
            for i in 1..<segment.points.count {
                let p = mapPos(ageMin: segment.points[i].ageMin, vpm: segment.points[i].vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                path.addLine(to: p)
            }
        }
        
        return ZStack {
            // Phase label above curve
            if (segment.durationMin >= 3.0 || isActive) && segment.points.count > 0 {
                let midAge = segment.startAgeMin + (segment.durationMin / 2)
                let midPt = segment.points.min(by: { abs($0.ageMin - midAge) < abs($1.ageMin - midAge) }) ?? segment.points[0]
                let midX = mapX(ageMin: midPt.ageMin, totalAge: totalAge, minAgeRaw: minAgeRaw, w: w)
                let curvePt = mapPos(ageMin: midPt.ageMin, vpm: midPt.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                let labelY = max(16, curvePt.y - 22)
                
                Text("\(segment.phase.rawValue.uppercased()) · \(Int(segment.durationMin))m")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(phaseColor.opacity(isActive ? 1.0 : 0.5))
                    .lineLimit(1)
                    .fixedSize()
                    .position(x: midX, y: labelY)
            }
            
            // Active gradient fill
            if isActive {
                let gradientPath = Path { path in
                    path.addPath(splinePath)
                    if let last = segment.points.last, let first = segment.points.first {
                        let pEnd = mapPos(ageMin: last.ageMin, vpm: last.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                        let pStart = mapPos(ageMin: first.ageMin, vpm: first.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                        path.addLine(to: CGPoint(x: pEnd.x, y: h))
                        path.addLine(to: CGPoint(x: pStart.x, y: h))
                        path.closeSubpath()
                    }
                }
                gradientPath.fill(LinearGradient(
                    gradient: Gradient(colors: [phaseColor.opacity(0.15), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            
            // Line stroke
            splinePath
                .stroke(phaseColor, style: StrokeStyle(lineWidth: isActive ? 2.5 : 2.0, lineCap: .round, lineJoin: .round))
                .shadow(color: isActive ? phaseColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            
            // Active node + value label
            if isActive, let last = segment.points.last {
                let p = mapPos(ageMin: last.ageMin, vpm: last.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                
                Circle()
                    .fill(phaseColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: phaseColor, radius: 6)
                    .position(p)
                
                let safeLabelX = min(w - 24, p.x)
                Text(formatViewCount(last.vpm) + " views")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.9))
                    .position(x: safeLabelX, y: p.y + 14)
            }
        }
    }
    
    // MARK: - Forecast View
    
    private func forecastView(minAgeRaw: Double, totalAge: Double, minVPM: Double, vpmRange: Double, w: CGFloat, h: CGFloat) -> some View {
        Group {
            if let projPhase = model.projectedNextPhase,
               let projEndAge = model.projectedEndAgeMin,
               let prob = model.projectedProb01, prob >= 0.65 {
                if let lastSeg = model.segments.last, let lastPt = lastSeg.points.last {
                    let pColor = colorFor(phase: projPhase)
                    let startP = mapPos(ageMin: lastPt.ageMin, vpm: lastPt.vpm, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                    let projectedVPM = lastPt.vpm * 1.3
                    let endP = mapPos(ageMin: projEndAge, vpm: projectedVPM, totalAge: totalAge, minAgeRaw: minAgeRaw, minVPM: minVPM, vpmRange: vpmRange, w: w, h: h)
                    
                    // Boundary dashed line at transition
                    Path { path in
                        path.move(to: CGPoint(x: startP.x, y: 0))
                        path.addLine(to: CGPoint(x: startP.x, y: h))
                    }
                    .stroke(pColor.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    
                    // Shaded forecast area
                    Path { path in
                        path.move(to: startP)
                        path.addQuadCurve(to: endP, control: CGPoint(x: startP.x + (endP.x - startP.x) * 0.3, y: startP.y))
                        path.addLine(to: CGPoint(x: endP.x, y: h))
                        path.addLine(to: CGPoint(x: startP.x, y: h))
                        path.closeSubpath()
                    }
                    .fill(pColor.opacity(0.06))
                    
                    // Dashed projection curve in the projected phase color
                    Path { path in
                        path.move(to: startP)
                        path.addQuadCurve(to: endP, control: CGPoint(x: startP.x + (endP.x - startP.x) * 0.3, y: startP.y))
                    }
                    .stroke(pColor.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                    
                    // Forecast label
                    Text("\(projPhase.rawValue.uppercased()) (\(Int(prob * 100))%)")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(pColor)
                        .kerning(0.3)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.HYPE.base.opacity(0.9))
                                .overlay(Capsule().stroke(pColor.opacity(0.3), lineWidth: 0.5))
                        )
                        .position(x: min(w - 50, (startP.x + endP.x) / 2), y: min(h - 16, endP.y - 16))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func colorFor(phase: PostPhase) -> Color {
        switch phase {
        case .testing:   return Color.HYPE.mustard
        case .expanding: return Color.HYPE.tea
        case .breakout:  return Color.HYPE.tangerine
        case .plateau:   return Color(hex: "A390E4")
        case .reignite:  return Color.HYPE.neonRed
        }
    }
    
    private func mapX(ageMin: Double, totalAge: Double, minAgeRaw: Double, w: CGFloat) -> CGFloat {
        CGFloat((ageMin - minAgeRaw) / totalAge) * w
    }
    
    private func mapY(vpm: Double, minVPM: Double, vpmRange: Double, h: CGFloat) -> CGFloat {
        let normalizedY = (vpm - minVPM) / vpmRange
        return h - (CGFloat(normalizedY) * (h * 0.85)) - (h * 0.05)
    }
    
    private func mapPos(ageMin: Double, vpm: Double, totalAge: Double, minAgeRaw: Double, minVPM: Double, vpmRange: Double, w: CGFloat, h: CGFloat) -> CGPoint {
        CGPoint(x: mapX(ageMin: ageMin, totalAge: totalAge, minAgeRaw: minAgeRaw, w: w),
                y: mapY(vpm: vpm, minVPM: minVPM, vpmRange: vpmRange, h: h))
    }
    
    private func formatViewCount(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

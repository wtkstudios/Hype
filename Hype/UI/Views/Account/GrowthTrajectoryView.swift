import SwiftUI

/// Clean line graph for growth trajectory with date X-axis, per-period gain Y-axis, and tappable data points
struct GrowthTrajectoryView: View {
    let dataPoints: [GrowthDataPoint]
    let metricLabel: String
    
    @State private var drawProgress: CGFloat = 0
    @State private var selectedPoint: GrowthDataPoint? = nil
    @State private var isDragging: Bool = false
    
    // Margins for axes
    private let yAxisWidth: CGFloat = 40
    private let xAxisHeight: CGFloat = 28
    
    private var actualPoints: [GrowthDataPoint] {
        dataPoints.filter { !$0.isProjected }
    }
    
    private var projectedPoints: [GrowthDataPoint] {
        dataPoints.filter { $0.isProjected }
    }
    
    /// All points (actual + projected) for sweep interaction
    private var allInteractivePoints: [GrowthDataPoint] {
        dataPoints.sorted { $0.dayOffset < $1.dayOffset }
    }
    
    private var allValues: [Double] {
        dataPoints.map { $0.value }
    }
    
    private var minVal: Double {
        let m = allValues.min() ?? 0
        return max(0, m * 0.9)
    }
    private var maxVal: Double {
        let mx = allValues.max() ?? 1
        return mx == minVal ? mx + 1 : mx * 1.05
    }
    
    private var sortedAll: [GrowthDataPoint] {
        dataPoints.sorted { $0.dayOffset < $1.dayOffset }
    }
    
    private var minDayOffset: Int { sortedAll.first?.dayOffset ?? 0 }
    private var maxDayOffset: Int { sortedAll.last?.dayOffset ?? 1 }
    
    private var yTicks: [Double] {
        let count = 4
        let step = (maxVal - minVal) / Double(count)
        return (0...count).map { minVal + step * Double($0) }
    }
    
    private var xTicks: [Int] {
        let range = maxDayOffset - minDayOffset
        guard range > 0 else { return [minDayOffset] }
        let tickCount = min(5, range)
        let step = max(1, range / tickCount)
        var ticks: [Int] = []
        var current = minDayOffset
        while current <= maxDayOffset {
            ticks.append(current)
            current += step
        }
        if ticks.last != maxDayOffset { ticks.append(maxDayOffset) }
        return ticks
    }
    
    private var projectedEndValue: Double? {
        projectedPoints.sorted(by: { $0.dayOffset < $1.dayOffset }).last?.value
    }
    
    /// Determine the average value to classify peaks/dips
    private var averageValue: Double {
        let vals = actualPoints.map { $0.value }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Double(vals.count)
    }
    
    /// Find nearest data point to an X position
    private func nearestPoint(to xPos: CGFloat, width: CGFloat) -> GrowthDataPoint? {
        guard !allInteractivePoints.isEmpty else { return nil }
        var closest: GrowthDataPoint?
        var closestDist: CGFloat = .greatestFiniteMagnitude
        for pt in allInteractivePoints {
            let ptX = xPosition(for: pt.dayOffset, width: width)
            let dist = abs(ptX - xPos)
            if dist < closestDist {
                closestDist = dist
                closest = pt
            }
        }
        return closest
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Metric label
            Text(metricLabel.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .kerning(0.8)
            
            HStack(alignment: .top, spacing: 0) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(yTicks.reversed(), id: \.self) { tick in
                        Text(formatAxisValue(tick))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.HYPE.text.opacity(0.3))
                            .frame(height: 0)
                        if tick != yTicks.first {
                            Spacer()
                        }
                    }
                }
                .frame(width: yAxisWidth, height: 160)
                .padding(.trailing, 4)
                
                VStack(spacing: 4) {
                    // Graph canvas
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        
                        ZStack {
                            // Horizontal grid lines
                            ForEach(yTicks, id: \.self) { tick in
                                let y = yPosition(for: tick, height: h)
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: w, y: y))
                                }
                                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                            }
                            
                            // Area fill
                            if actualPoints.count >= 2 {
                                areaFill(points: actualPoints, width: w, height: h)
                            }
                            
                            // Actual line
                            if actualPoints.count >= 2 {
                                linePath(points: actualPoints, width: w, height: h)
                                    .trim(from: 0, to: drawProgress)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.HYPE.tea.opacity(0.6), Color.HYPE.tea],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                                    )
                                    .shadow(color: Color.HYPE.tea.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            // Projected dashed line
                            if projectedPoints.count >= 2 {
                                linePath(points: projectedPoints, width: w, height: h)
                                    .trim(from: 0, to: drawProgress)
                                    .stroke(
                                        Color.HYPE.tea.opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [6, 4])
                                    )
                            }
                            
                            // Projected endpoint annotation (only when not dragging)
                            if selectedPoint == nil,
                               let endVal = projectedEndValue,
                               let lastPt = projectedPoints.sorted(by: { $0.dayOffset < $1.dayOffset }).last {
                                let x = xPosition(for: lastPt.dayOffset, width: w)
                                let y = yPosition(for: endVal, height: h)
                                
                                Circle()
                                    .fill(Color.HYPE.tea.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                    .position(x: x, y: y)
                                
                                Text(formatAxisValue(endVal))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.HYPE.tea)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.HYPE.base)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.HYPE.tea.opacity(0.3), lineWidth: 0.5)
                                            )
                                    )
                                    .position(x: min(x, w - 24), y: max(y - 14, 10))
                            }
                            
                            // Data point dots
                            ForEach(allInteractivePoints) { pt in
                                let x = xPosition(for: pt.dayOffset, width: w)
                                let y = yPosition(for: pt.value, height: h)
                                let isSelected = selectedPoint?.dayOffset == pt.dayOffset
                                
                                Circle()
                                    .fill(isSelected ? Color.HYPE.tea : (pt.isProjected ? Color.HYPE.tea.opacity(0.3) : Color.HYPE.tea.opacity(0.5)))
                                    .frame(width: isSelected ? 10 : 5, height: isSelected ? 10 : 5)
                                    .shadow(color: isSelected ? Color.HYPE.tea.opacity(0.6) : .clear, radius: 4)
                                    .position(x: x, y: y)
                                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                            }
                            
                            // Selection vertical line
                            if let sel = selectedPoint {
                                let x = xPosition(for: sel.dayOffset, width: w)
                                Path { path in
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: h))
                                }
                                .stroke(Color.HYPE.text.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            }
                            
                            // Tooltip card for selected point
                            if let sel = selectedPoint {
                                let x = xPosition(for: sel.dayOffset, width: w)
                                let y = yPosition(for: sel.value, height: h)
                                
                                pointTooltip(for: sel)
                                    .position(
                                        x: x < w / 2 ? min(x + 70, w - 50) : max(x - 70, 50),
                                        y: max(y - 30, 35)
                                    )
                                    .transition(.opacity)
                            }
                        }
                        // Sweep / drag gesture overlay
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    isDragging = true
                                    let xPos = drag.location.x
                                    if let nearest = nearestPoint(to: xPos, width: w) {
                                        if selectedPoint?.dayOffset != nearest.dayOffset {
                                            // Haptic tick on each new point
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
                                    // Keep tooltip visible — user can tap background to dismiss
                                }
                        )
                        .onTapGesture {
                            // Tap background to dismiss tooltip
                            if selectedPoint != nil && !isDragging {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPoint = nil
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                    
                    // X-axis: real dates
                    GeometryReader { geo in
                        let w = geo.size.width
                        ForEach(xTicks, id: \.self) { dayOffset in
                            let x = xPosition(for: dayOffset, width: w)
                            Text(formatDateLabel(dayOffset))
                                .font(.system(size: 7, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.HYPE.text.opacity(0.3))
                                .position(x: x, y: 8)
                        }
                    }
                    .frame(height: xAxisHeight)
                }
            }
            
            // Legend
            if !projectedPoints.isEmpty {
                HStack(spacing: 6) {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 4))
                        path.addLine(to: CGPoint(x: 20, y: 4))
                    }
                    .stroke(Color.HYPE.tea.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .frame(width: 20, height: 8)
                    
                    Text("PROJECTED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.3))
                        .kerning(0.5)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                drawProgress = 1.0
            }
        }
    }
    
    // MARK: - Tooltip
    
    private func pointTooltip(for point: GrowthDataPoint) -> some View {
        let dateStr = formatDateLabel(point.dayOffset)
        let valueStr = formatAxisValue(point.value)
        let pctOfAvg = averageValue > 0 ? ((point.value - averageValue) / averageValue) * 100 : 0
        let trend = pctOfAvg >= 10 ? "Peak" : (pctOfAvg <= -10 ? "Dip" : "Steady")
        let trendColor = pctOfAvg >= 10 ? Color.HYPE.tea : (pctOfAvg <= -10 ? Color(hex: "E6A23C") : Color.HYPE.text.opacity(0.6))
        
        // Generate a concise insight
        let insight: String
        if pctOfAvg >= 20 {
            insight = "Strong spike — likely viral push or trending content"
        } else if pctOfAvg >= 10 {
            insight = "Above average — good momentum in this period"
        } else if pctOfAvg <= -20 {
            insight = "Significant dip — possible low posting or algo shift"
        } else if pctOfAvg <= -10 {
            insight = "Below average — engagement may have slowed"
        } else {
            insight = "Consistent with your typical performance"
        }
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(dateStr)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
                
                Text(trend.uppercased())
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(trendColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(trendColor.opacity(0.15))
                    .cornerRadius(3)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPoint = nil
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                        .frame(width: 16, height: 16)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
            
            HStack(spacing: 4) {
                Text(valueStr)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
                
                Text(String(format: "%+.0f%%", pctOfAvg))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(trendColor)
            }
            
            Text(insight)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(Color.HYPE.text.opacity(0.45))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.HYPE.base.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
        .frame(width: 140)
    }
    
    // MARK: - Position Helpers
    
    private func xPosition(for dayOffset: Int, width: CGFloat) -> CGFloat {
        let totalRange = CGFloat(maxDayOffset - minDayOffset)
        guard totalRange > 0 else { return width / 2 }
        return ((CGFloat(dayOffset) - CGFloat(minDayOffset)) / totalRange) * width
    }
    
    private func yPosition(for value: Double, height: CGFloat) -> CGFloat {
        let range = maxVal - minVal
        guard range > 0 else { return height / 2 }
        return height - ((CGFloat(value - minVal) / CGFloat(range)) * height)
    }
    
    // MARK: - Formatters
    
    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else if value < 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    private func formatDateLabel(_ dayOffset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Path Builders
    
    private func linePath(points: [GrowthDataPoint], width: CGFloat, height: CGFloat) -> Path {
        let sorted = points.sorted { $0.dayOffset < $1.dayOffset }
        var path = Path()
        for (i, pt) in sorted.enumerated() {
            let x = xPosition(for: pt.dayOffset, width: width)
            let y = yPosition(for: pt.value, height: height)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
    
    private func areaFill(points: [GrowthDataPoint], width: CGFloat, height: CGFloat) -> some View {
        let sorted = points.sorted { $0.dayOffset < $1.dayOffset }
        var path = Path()
        for (i, pt) in sorted.enumerated() {
            let x = xPosition(for: pt.dayOffset, width: width)
            let y = yPosition(for: pt.value, height: height)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        if let lastPt = sorted.last {
            path.addLine(to: CGPoint(x: xPosition(for: lastPt.dayOffset, width: width), y: height))
        }
        if let firstPt = sorted.first {
            path.addLine(to: CGPoint(x: xPosition(for: firstPt.dayOffset, width: width), y: height))
        }
        path.closeSubpath()
        return path.fill(
            LinearGradient(
                colors: [Color.HYPE.tea.opacity(0.08), Color.HYPE.tea.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

/// Mock data generator — produces per-period GAINS (not cumulative totals)
struct GrowthDataGenerator {
    static func generate(for timeframe: DashboardTimeframe, metric: GrowthMetricType) -> [GrowthDataPoint] {
        let days = timeframe.days
        var points: [GrowthDataPoint] = []
        
        let dailyGainBase: Double
        switch metric {
        case .followers:  dailyGainBase = 450
        case .views:      dailyGainBase = 85_000
        case .engagement: dailyGainBase = 0.18
        case .shares:     dailyGainBase = 1_200
        case .comments:   dailyGainBase = 3_500
        }
        
        let step = max(days / 30, 1)
        
        for i in stride(from: -days, through: 0, by: step) {
            let noise = Double.random(in: -0.35...0.55)
            let periodDays = Double(step)
            let gain = dailyGainBase * periodDays * (1.0 + noise)
            points.append(GrowthDataPoint(dayOffset: i, value: max(0, gain), isProjected: false))
        }
        
        let avgRecentGain: Double
        if points.count >= 3 {
            let recentSlice = points.suffix(3)
            avgRecentGain = recentSlice.map { $0.value }.reduce(0, +) / Double(recentSlice.count)
        } else {
            avgRecentGain = dailyGainBase * Double(step)
        }
        
        for i in stride(from: step, through: 7, by: step) {
            let projectedGain = avgRecentGain * Double.random(in: 0.95...1.1)
            points.append(GrowthDataPoint(dayOffset: i, value: max(0, projectedGain), isProjected: true))
        }
        if points.last?.dayOffset != 7 {
            let projectedGain = avgRecentGain * Double.random(in: 0.95...1.1)
            points.append(GrowthDataPoint(dayOffset: 7, value: max(0, projectedGain), isProjected: true))
        }
        
        return points
    }
}

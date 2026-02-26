import SwiftUI

struct PostDetailView: View {
    let video: VideoCardData
    
    var body: some View {
        ZStack {
            Color.HYPE.base.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    header
                    scoreModule
                    velocityGraph
                    keyDrivers
                    nextAction
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 120)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                
                Text("Posted 24m ago")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
            }
            Spacer()
        }
    }
    
    private var scoreModule: some View {
        VStack(spacing: 8) {
            Text("HYPE SCORE")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(video.phase.color)
                .kerning(1)
            
            ZStack {
                Text(String(format: "%.1f", video.score))
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(Color.HYPE.text)
                
                // Diagonal marker highlight matching the current phase
                Rectangle()
                    .fill(video.phase.color.opacity(0.3))
                    .frame(width: 140, height: 20)
                    .rotationEffect(.degrees(-5))
                    .offset(y: 20)
            }
            
            PhaseTimelineView(prediction: PhasePrediction(
                currentPhase: video.phase,
                nextPhase: .hyper,
                nextPhaseProbability: 0.85,
                updatedAt: Date()
            ))
        }
    }
    
    private var velocityGraph: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VELOCITY")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 180)
                    .cornerRadius(12)
                
                // Baseline Shaded Range (IQR/StdDev representation)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 130))
                    path.addLine(to: CGPoint(x: 340, y: 90))
                    path.addLine(to: CGPoint(x: 340, y: 150))
                    path.addLine(to: CGPoint(x: 0, y: 170))
                }
                .fill(LinearGradient(
                    gradient: Gradient(colors: [video.phase.color.opacity(0.15), video.phase.color.opacity(0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                
                // Ghost Line (Forecasted Next 60m)
                Path { path in
                    path.move(to: CGPoint(x: 200, y: 40))
                    path.addCurve(to: CGPoint(x: 340, y: 25), control1: CGPoint(x: 250, y: 30), control2: CGPoint(x: 300, y: 25))
                }
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4]))
                .foregroundColor(Color.HYPE.text.opacity(0.3))
                
                // Actual Velocity Line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 150))
                    path.addCurve(to: CGPoint(x: 100, y: 90), control1: CGPoint(x: 40, y: 130), control2: CGPoint(x: 70, y: 90))
                    path.addCurve(to: CGPoint(x: 200, y: 40), control1: CGPoint(x: 140, y: 90), control2: CGPoint(x: 170, y: 40))
                }
                .stroke(video.phase.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Latest Point Node
                Circle()
                    .fill(Color.HYPE.base)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(video.phase.color, lineWidth: 2))
                    .position(x: 200, y: 40)
            }
        }
    }
    
    // Mock DriverPack for rendering since real data plumbing requires VM updates
    private var mockDriverPack: DriverPack {
        let builder = DriverPackBuilder()
        // Simulate a snapshot & baseline
        let now = Date()
        let snap1 = VideoSnapshot(videoId: video.id, timestamp: now, createdAt: now.addingTimeInterval(-1800), views: 15400, likes: 2300, comments: 120, shares: 450)
        let snap2 = VideoSnapshot(videoId: video.id, timestamp: now.addingTimeInterval(-600), createdAt: now.addingTimeInterval(-1800), views: 9000, likes: 1200, comments: 80, shares: 150)
        let baseline = BaselineBucket(bucket: .min15_30, medianVPM: 200, iqrVPM: 50, medianEPR: 0.1, iqrEPR: 0.05, medianSPM: 5, iqrSPM: 2, medianACC: 0, iqrACC: 5, sampleSize: 20)
        return builder.buildDriverPack(currentSnapshot: snap1, previousSnapshot: snap2, prevPrevSnapshot: nil, baseline: baseline, confidence01: 0.85, recentVpmHistory: [250, 300, 280], recentAccHistory: [10, -5, 20], recentSpmHistory: [8, 12, 9])
    }
    
    private var keyDrivers: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DRIVERS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.primary)
                Text("Compared to your baseline at this stage.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
            }
            
            // 2x2 Grid of Driver Cards
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(mockDriverPack.insights) { insight in
                    DriverCardView(insight: insight)
                }
            }
            
            // HYPE Composition Bar
            VStack(alignment: .leading, spacing: 8) {
                Text("HYPE COMPOSITION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.4))
                
                let contribs = mockDriverPack.contribution
                let cVel = CGFloat(contribs["Velocity"] ?? 0)
                let cShr = CGFloat(contribs["Shares"] ?? 0)
                let cAcc = CGFloat(contribs["Acceleration"] ?? 0)
                let cEng = CGFloat(contribs["Engagement"] ?? 0)
                let total = cVel + cShr + cAcc + cEng > 0 ? (cVel + cShr + cAcc + cEng) : 100.0
                
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.HYPE.tangerine).frame(width: max(0, (cVel / total) * geo.size.width - 2))
                        Rectangle().fill(Color.HYPE.primary).frame(width: max(0, (cShr / total) * geo.size.width - 2))
                        Rectangle().fill(Color.HYPE.sky).frame(width: max(0, (cAcc / total) * geo.size.width - 2))
                        Rectangle().fill(Color.HYPE.tea).frame(width: max(0, (cEng / total) * geo.size.width - 2))
                    }
                }
                .frame(height: 6)
                .cornerRadius(3)
                
                // Legend
                HStack(spacing: 12) {
                    legendItem(color: Color.HYPE.tangerine, text: "Velocity")
                    legendItem(color: Color.HYPE.primary, text: "Shares")
                    legendItem(color: Color.HYPE.sky, text: "Accel.")
                    legendItem(color: Color.HYPE.tea, text: "Engage.")
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
        }
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.HYPE.text.opacity(0.6))
        }
    }
    
    private var nextAction: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NEXT ACTION")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Respond with Video Reply")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                
                ExpandableWhyView(
                    drivers: [
                        DriverItem(title: "Velocity", delta: "+150%", impact: "Positive"),
                        DriverItem(title: "Phase", delta: "Expanding", impact: "Positive")
                    ],
                    confidence: 0.88
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(video.phase.color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(video.phase.color.opacity(0.3), lineWidth: 1)
            )
            
            TrajectoryPanelView(forecast: ForecastSnapshot(
                videoId: video.id,
                computedAt: Date(),
                expected24hLow: 120_000,
                expected24hHigh: 190_000,
                confidence: .high,
                trajectorySummary: "Current momentum suggests expansion with 85% chance of secondary push."
            ))
            .padding(.top, 8)
        }
    }
}

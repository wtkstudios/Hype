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
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        HStack {
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
            .padding(.bottom, 8)
            
            // HYPE COMPOSITION (out of 10) under Score
            VStack(alignment: .leading, spacing: 12) {
                Text("HYPE COMPOSITION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.4))
                
                let contribs = mockDriverPack.contribution
                let cVel = CGFloat(contribs["Velocity"] ?? 0)
                let cShr = CGFloat(contribs["Shares"] ?? 0)
                let cAcc = CGFloat(contribs["Acceleration"] ?? 0)
                let cEng = CGFloat(contribs["Engagement"] ?? 0)
                let rawTotal = cVel + cShr + cAcc + cEng > 0 ? (cVel + cShr + cAcc + cEng) : 100.0
                
                let wVel = cVel / rawTotal
                let wShr = cShr / rawTotal
                let wAcc = cAcc / rawTotal
                let wEng = cEng / rawTotal
                
                // Total is mapping directly to the actual out-of-10 hype score points math requested
                let outOfTenScore = video.score / 10.0
                
                GeometryReader { geo in
                    let w = geo.size.width
                    let spacing: CGFloat = 3
                    let availableW = max(0, w - (spacing * 3))
                    
                    HStack(alignment: .bottom, spacing: spacing) {
                        if cVel > 0 { compSegment(width: availableW * wVel, color: Color.HYPE.tangerine, label: "Vel", percent: outOfTenScore * wVel) }
                        if cShr > 0 { compSegment(width: availableW * wShr, color: Color.HYPE.primary, label: "Share", percent: outOfTenScore * wShr) }
                        if cAcc > 0 { compSegment(width: availableW * wAcc, color: Color.HYPE.neonGreen, label: "Accel", percent: outOfTenScore * wAcc) }
                        if cEng > 0 { compSegment(width: availableW * wEng, color: Color.HYPE.tea, label: "Eng", percent: outOfTenScore * wEng) }
                    }
                }
                .frame(height: 32)
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            
            // 24H Trajectory moved under Hype Composition
            TrajectoryPanelView(forecast: ForecastSnapshot(
                videoId: video.id,
                computedAt: Date(),
                expected24hLow: 120_000,
                expected24hHigh: 190_000,
                confidence: .high,
                trajectorySummary: "Current momentum suggests expansion with 85% chance of secondary push."
            ))
            .padding(.top, 4)
        }
    }
    
    // Mock LifecycleLineModel for rendering since real data plumbing requires VM updates
    private var mockLifecycleLine: LifecycleLineModel {
        let builder = LifecycleLineBuilder()
        // Simulate snapshots over time
        let now = Date()
        let snaps = [
            VideoSnapshot(videoId: video.id, timestamp: now.addingTimeInterval(-2400), createdAt: now.addingTimeInterval(-3600), views: 1000, likes: 50, comments: 5, shares: 10),
            VideoSnapshot(videoId: video.id, timestamp: now.addingTimeInterval(-1800), createdAt: now.addingTimeInterval(-3600), views: 3000, likes: 200, comments: 20, shares: 40),
            VideoSnapshot(videoId: video.id, timestamp: now.addingTimeInterval(-600), createdAt: now.addingTimeInterval(-3600), views: 12000, likes: 1000, comments: 80, shares: 350),
            VideoSnapshot(videoId: video.id, timestamp: now, createdAt: now.addingTimeInterval(-3600), views: 25000, likes: 2500, comments: 150, shares: 600)
        ]
        
        let hist = [
            (now.addingTimeInterval(-2400), HypeComputation(hypeScore: 20, hypeRaw01: 0.2, confidence01: 0.9, phase: .testing, breakoutProb01: 0.1, weights: nil)),
            (now.addingTimeInterval(-1800), HypeComputation(hypeScore: 50, hypeRaw01: 0.5, confidence01: 0.9, phase: .expanding, breakoutProb01: 0.4, weights: nil)),
            (now.addingTimeInterval(-600), HypeComputation(hypeScore: 85, hypeRaw01: 0.85, confidence01: 0.95, phase: .expanding, breakoutProb01: 0.85, weights: nil)),
            (now, HypeComputation(hypeScore: 92, hypeRaw01: 0.92, confidence01: 0.95, phase: .breakout, breakoutProb01: 0.9, weights: nil))
        ]
        
        return builder.buildModel(snapshots: snaps, hypeHistory: hist, now: now)
    }
    
    private var velocityGraph: some View {
        VStack(spacing: 12) {
            DistributionLifecycleCard(model: mockLifecycleLine)
            
            PhaseTimelineView(prediction: PhasePrediction(
                currentPhase: video.phase,
                nextPhase: .breakout,
                nextPhaseProbability: 0.85,
                updatedAt: Date()
            ))
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
        return builder.buildDriverPack(currentSnapshot: snap1, previousSnapshot: snap2, prevPrevSnapshot: nil, baseline: baseline, confidence01: 0.85, recentVpmHistory: [250, 300, 280], recentAccHistory: [10, -5, 20], recentSpmHistory: [8, 12, 9], now: now)
    }
    
    private var keyDrivers: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DRIVERS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.primary)
                Text("Compared to your baseline.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
            }
            
            // Calculate Top Driver for Highlights (must be Strong)
            let topDriverId = mockDriverPack.insights
                .filter { $0.strength == .strong }
                .max(by: { $0.impactScore < $1.impactScore })?.id
            
            // 2x2 Grid of Driver Cards
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(mockDriverPack.insights) { insight in
                    DriverCardView(insight: insight, isTopDriver: insight.id == topDriverId)
                }
            }
        }
    }
    
    // Segment rendering helper with percentage logic -> mapped to points out of 10
    private func compSegment(width: CGFloat, color: Color, label: String, percent: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label) \(String(format: "%.1f", percent))pts")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Rectangle()
                .fill(color)
                .frame(height: 10)
                .cornerRadius(2)
        }
        .frame(width: max(0, width), alignment: .leading)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.HYPE.text.opacity(0.6))
        }
    }
}

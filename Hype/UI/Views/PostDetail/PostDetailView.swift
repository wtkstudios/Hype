import SwiftUI
import Combine

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let video: VideoCardData
    
    // State for smooth close animation
    @State private var isClosing = false
    
    var body: some View {
        ZStack {
            Color.HYPE.base.ignoresSafeArea()
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 32) {
                        customHeader
                        scoreModule
                        velocityGraph
                        keyDrivers(proxy: proxy)
                        nextActionCard
                    }
                    .padding()
                }
            }
            .opacity(isClosing ? 0 : 1)
            .scaleEffect(isClosing ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isClosing)
        }
        .navigationBarHidden(true)
        .enableSwipeBack()
        .interactiveDismissDisabled(isClosing) // Prevent standard swipe while animating
    }
    
    private var customHeader: some View {
        ZStack(alignment: .top) {
            // Centered Title and Time
            VStack(spacing: 4) {
                Text(video.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("Posted 24m ago")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
            }
            .padding(.horizontal, 50) // Keep text away from the close button
            .padding(.top, 4)
            .frame(maxWidth: .infinity)
            
            // Top Left Close Button
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isClosing = true
                    }
                    // Delay dismiss slightly to allow animation to play
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.HYPE.text.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                Spacer()
            }
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
            
            Text("Out of 100pts")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .padding(.bottom, 8)
            
            // Move PhaseTimelineView (Lifecycle Phase) above the 24H Trajectory
            PhaseTimelineView(prediction: PhasePrediction(
                currentPhase: video.phase,
                nextPhase: .breakout,
                nextPhaseProbability: 0.85,
                updatedAt: Date()
            ))
            .padding(.top, 8)
            
            // Real-time metric trackers
            RealtimeTickersView(video: video)
                .padding(.top, 16)
                
            // 24H Trajectory
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
    
    private func keyDrivers(proxy: ScrollViewProxy) -> some View {
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
                    DriverCardView(insight: insight, isTopDriver: insight.id == topDriverId) {
                        withAnimation {
                            proxy.scrollTo(insight.id, anchor: .center)
                        }
                    }
                    .id(insight.id)
                }
            }
        }
    }
    
    private var nextActionCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT ACTION")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color.HYPE.primary)
                
                Text(video.phase == .expanding ? "Respond to top comment" : "Pin new video hook")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                
                Text(video.phase == .expanding ? "High Confidence (88%)" : "Medium Confidence")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }) {
                Text("Execute")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.base)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.HYPE.tangerine) // Strict constraint: Tangerine ONLY for primary executions
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.HYPE.primary.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct RealtimeTickersView: View {
    let video: VideoCardData
    
    @State private var views: Int
    @State private var likes: Int
    @State private var comments: Int
    @State private var shares: Int
    
    // Timer to simulate live data ticking up
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    init(video: VideoCardData) {
        self.video = video
        
        // Synthesize realistic base metrics from the video score
        let baseViews = max(Int(video.score * 1250), 1500)
        self._views = State(wrappedValue: baseViews)
        self._likes = State(wrappedValue: Int(Double(baseViews) * 0.08)) // ~8% like rate
        self._comments = State(wrappedValue: Int(Double(baseViews) * 0.009)) // ~0.9% comment rate
        self._shares = State(wrappedValue: Int(Double(baseViews) * 0.015)) // ~1.5% share rate
    }
    
    var body: some View {
        HStack(spacing: 0) {
            TickerItemView(title: "VIEWS", value: views)
            divider
            TickerItemView(title: "LIKES", value: likes)
            divider
            TickerItemView(title: "CMNTS", value: comments)
            divider
            TickerItemView(title: "SHARES", value: shares)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.primary.opacity(0.2), lineWidth: 1)
        )
        // Simulator tick
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                // Random deterministic jitter based on phase acceleration
                let vStep = Int.random(in: 1...15)
                views += vStep
                
                if vStep > 10 { likes += Int.random(in: 1...3) }
                if vStep == 15 { comments += 1 }
                if vStep % 5 == 0 { shares += 1 }
            }
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 24)
    }
    
    
}

private struct TickerItemView: View {
    let title: String
    let value: Int
    
    @State private var flashScale: CGFloat = 1.0
    @State private var flashColor: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .kerning(0.5)
            
            let formatter = NumberFormatter()
            let _ = formatter.numberStyle = .decimal
            let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
            let characters = Array(valueStr)
            
            HStack(spacing: 0) {
                ForEach(0..<characters.count, id: \.self) { index in
                    let placeValue = characters.count - 1 - index
                    DigitView(char: characters[index])
                        .id(placeValue)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DigitView: View {
    let char: Character
    
    @State private var flashScale: CGFloat = 1.0
    @State private var flashColor: Color = .white
    
    var body: some View {
        Text(String(char))
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(flashColor)
            .scaleEffect(flashScale)
            .shadow(color: flashColor == Color.HYPE.tea ? Color.HYPE.tea.opacity(0.6) : .clear, radius: 4)
            .contentTransition(.numericText()) // Smooth iOS 16 native numeric scroll
            .onChange(of: char) { newValue in
                // Only animate digits, not commas
                guard newValue.isNumber else { return }
                
                let impact = UIImpactFeedbackGenerator(style: .soft)
                impact.prepare()
                impact.impactOccurred(intensity: 0.6)
                
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    flashScale = 1.15
                    flashColor = Color.HYPE.tea
                }
                
                // Revert quickly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        flashScale = 1.0
                        flashColor = .white
                    }
                }
            }
    }
}

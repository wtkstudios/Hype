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
                .foregroundColor(Color.HYPE.primary)
                .kerning(1)
            
            ZStack {
                Text(String(format: "%.1f", video.score))
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(Color.HYPE.text)
                
                // Diagonal marker highlight (Single instance of Tangerine permitted)
                Rectangle()
                    .fill(Color.HYPE.tangerine.opacity(0.3))
                    .frame(width: 140, height: 20)
                    .rotationEffect(.degrees(-5))
                    .offset(y: 20)
            }
            
            PhaseTimelineView(prediction: PhasePrediction(
                currentPhase: video.phase,
                nextPhase: .secondaryPush,
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
                    gradient: Gradient(colors: [Color.HYPE.primary.opacity(0.15), Color.HYPE.primary.opacity(0.0)]),
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
                .stroke(Color.HYPE.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Latest Point Node
                Circle()
                    .fill(Color.HYPE.base)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.HYPE.primary, lineWidth: 2))
                    .position(x: 200, y: 40)
            }
        }
    }
    
    private var keyDrivers: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DRIVERS")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            HStack(spacing: 12) {
                driverCard(title: "Velocity", value: "High", color: Color.HYPE.primary)
                driverCard(title: "Shares", value: "4.2%", color: Color.HYPE.tea) // Strict constraint: Use Tea, not Energy
                driverCard(title: "Comments", value: "Avg", color: Color.HYPE.text.opacity(0.5))
            }
        }
    }
    
    private func driverCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Color.HYPE.text.opacity(0.5))
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
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
            .background(Color.HYPE.primary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.HYPE.primary.opacity(0.3), lineWidth: 1)
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

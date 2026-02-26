import SwiftUI

struct PhaseTimelineView: View {
    let prediction: PhasePrediction
    
    // Order of lifecycle phases
    let phases: [DistributionPhase] = [.testing, .expanding, .breakout, .plateau, .reignite]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFECYCLE PHASE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            HStack(spacing: 8) {
                ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                    let isActive = phase == prediction.currentPhase
                    let isNext = phase == prediction.nextPhase
                    PhaseIndicatorNode(phase: phase, isActive: isActive)
                }
            }
            
            if prediction.nextPhase != .unknown {
                HStack(spacing: 4) {
                    Text("ESTIMATED NEXT:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                    
                    Text("\(prediction.nextPhase.rawValue.uppercased()) (\(Int(prediction.nextPhaseProbability * 100))%)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(prediction.nextPhase.color)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Subcomponents

struct PhaseIndicatorNode: View {
    let phase: DistributionPhase
    let isActive: Bool
    
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 6) {
            // The track
            Rectangle()
                .fill(isActive ? phase.activeColor : phase.color.opacity(0.2))
                .frame(height: isActive && phase == .breakout && isPulsing ? 6 : 4)
                .cornerRadius(2)
                .shadow(
                    color: isActive ? phase.activeColor.opacity(isPulsing ? 0.9 : 0.4) : .clear,
                    radius: isActive ? (phase == .breakout && isPulsing ? 8 : 4) : 0,
                    x: 0,
                    y: 0
                )
            
            // Phase Label
            Text(phase.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isActive ? phase.activeColor : phase.color.opacity(0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(
                    color: isActive ? phase.activeColor.opacity(isPulsing ? 0.8 : 0.3) : .clear,
                    radius: isActive ? (phase == .breakout && isPulsing ? 6 : 2) : 0,
                    x: 0,
                    y: 0
                )
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(isActive && phase == .breakout && isPulsing ? 1.05 : 1.0)
        .onAppear {
            if isActive {
                withAnimation(
                    .easeInOut(duration: phase == .breakout ? 0.35 : 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
        }
    }
}

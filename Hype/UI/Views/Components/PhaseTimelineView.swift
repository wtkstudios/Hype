import SwiftUI

struct PhaseTimelineView: View {
    let prediction: PhasePrediction
    
    // Order of lifecycle phases
    let phases: [DistributionPhase] = [.testing, .expanding, .hyper, .plateau, .reignite]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFECYCLE PHASE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            HStack(spacing: 8) {
                ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                    let isActive = phase == prediction.currentPhase
                    let isNext = phase == prediction.nextPhase
                    
                    VStack(spacing: 6) {
                        // The track
                        Rectangle()
                            .fill(isActive ? phase.color : (isNext ? phase.color.opacity(0.3) : Color.white.opacity(0.1)))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        // Phase Label
                        Text(phase.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isActive ? phase.color : Color.HYPE.text.opacity(0.4))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
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

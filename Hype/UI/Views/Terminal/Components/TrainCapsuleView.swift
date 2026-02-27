import SwiftUI

struct TrainCapsuleView: View {
    let phase: DistributionPhase
    let isAccelerating: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            SwiftUI.Circle()
                .fill(isAccelerating ? Color.HYPE.neonGreen : Color.clear)
                .frame(width: 4, height: 4)
                .shadow(color: isAccelerating ? Color.HYPE.neonGreen : Color.clear, radius: 2)
            
            Capsule()
                .fill(phase.color)
                .frame(width: 20, height: 10)
                .opacity(phase == .plateau ? 0.4 : 1.0)
        }
    }
}

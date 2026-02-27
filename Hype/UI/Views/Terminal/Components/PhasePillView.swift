import SwiftUI

struct PhasePillView: View {
    let phase: DistributionPhase
    
    var body: some View {
        Text(phase.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(phase.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(phase.color.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(phase.color.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
    }
}

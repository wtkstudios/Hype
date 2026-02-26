import SwiftUI

struct DistributionLifecycleCard: View {
    let model: LifecycleLineModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Minimal Header Footprint
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DISTRIBUTION LIFECYCLE")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                    Text("Phase + velocity over time")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                }
                
                Spacer()
                
                // Active Phase Pill
                Text(model.activePhase.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.HYPE.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.HYPE.primary.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // The Line Chart (Maximizing Space)
            LifecycleLineChartView(model: model)
                .frame(minHeight: 180, maxHeight: 220) 
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

import SwiftUI

struct DistributionLifecycleCard: View {
    let model: LifecycleLineModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Minimal Header Footprint
            VStack(alignment: .leading, spacing: 2) {
                Text("DISTRIBUTION LIFECYCLE")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.HYPE.primary)
                Text("Views over time")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
            }
            
            // The Line Chart (Maximizing Space)
            LifecycleLineChartView(model: model)
                .frame(minHeight: 230, maxHeight: 280) 
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

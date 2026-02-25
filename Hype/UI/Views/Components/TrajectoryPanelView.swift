import SwiftUI

struct TrajectoryPanelView: View {
    let forecast: ForecastSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("24H TRAJECTORY")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.text.opacity(0.7))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(forecast.confidence == .high ? Color.HYPE.tea : (forecast.confidence == .medium ? Color.HYPE.primary : Color.HYPE.error))
                        .frame(width: 6, height: 6)
                    
                    Text("\(forecast.confidence.rawValue.uppercased()) CONFIDENCE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if forecast.confidence == .low {
                    Text("Insufficient data for reliable 24h projection. Check back in 30 minutes.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(formatViews(forecast.expected24hLow))
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(Color.HYPE.text)
                        
                        Text("–")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(Color.HYPE.text.opacity(0.4))
                        
                        Text(formatViews(forecast.expected24hHigh))
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(Color.HYPE.text)
                    }
                    
                    Text(forecast.trajectorySummary)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.HYPE.text.opacity(0.8))
                        .lineSpacing(4)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatViews(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fk", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

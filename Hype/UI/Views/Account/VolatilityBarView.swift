import SwiftUI

/// Horizontal volatility bar: Stable (left/green) → Volatile (right/red)
struct VolatilityBarView: View {
    let stabilityLabel: StabilityLabel
    let volatilityStd: Double
    
    /// Normalized volatility 0–1 for bar fill
    private var normalizedVolatility: Double {
        // std 0–30 mapped to 0–1
        min(max(volatilityStd / 30.0, 0), 1.0)
    }
    
    private var barColor: Color {
        switch stabilityLabel {
        case .low:      return Color(hex: "2ECC71").opacity(0.7)  // muted emerald
        case .moderate: return Color(hex: "E6A23C").opacity(0.8)  // warm amber
        case .high:     return Color(hex: "C0392B").opacity(0.7)  // deep muted red
        }
    }
    
    private var label: String {
        switch stabilityLabel {
        case .low:      return "Stable"
        case .moderate: return "Moderate"
        case .high:     return "High"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("VOLATILITY INDEX")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color.HYPE.text.opacity(0.4))
                    .kerning(0.8)
                
                Spacer()
                
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(barColor)
            }
            
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "2ECC71").opacity(0.7), Color(hex: "E6A23C").opacity(0.8), Color(hex: "C0392B").opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * normalizedVolatility, height: 6)
                }
            }
            .frame(height: 6)
            
            // Scale labels
            HStack {
                Text("STABLE")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(Color.HYPE.text.opacity(0.25))
                Spacer()
                Text("VOLATILE")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(Color.HYPE.text.opacity(0.25))
            }
            
            // Tooltip
            if stabilityLabel == .high {
                Text("High volatility suggests inconsistent momentum.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "E6A23C").opacity(0.7))
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

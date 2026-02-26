import SwiftUI

struct DriverCardView: View {
    let insight: DriverInsight
    
    @State private var isExpanded = false
    
    // Custom neon accents per user request
    private let neonGreenAccent = Color(hex: "39FF88")
    private let neonRedAccent = Color(hex: "FF3B5C")
    
    private var strengthColor: Color {
        switch insight.strength {
        case .strong: return neonGreenAccent
        case .good: return Color.HYPE.tea
        case .neutral: return Color.HYPE.primary.opacity(0.6)
        case .weak: return neonRedAccent
        }
    }
    
    private var trendIcon: String {
        switch insight.trend {
        case .rising: return "arrow.up.right"
        case .flat: return "arrow.right"
        case .falling: return "arrow.down.right"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Card Content (Always visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    // Top Row: Title + Strength Pill
                    HStack {
                        Text(insight.kind.rawValue.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color.HYPE.text.opacity(0.8))
                        
                        Spacer()
                        
                        Text(insight.strength.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(strengthColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(strengthColor.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    // Middle Row: Big Metric
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.metricValue)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color.HYPE.text)
                        
                        Text(insight.metricLabel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.HYPE.primary.opacity(0.8))
                    }
                    
                    // Below: Secondary Label
                    Text(insight.secondaryLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(insight.secondaryLabel.contains("-") ? neonRedAccent : (insight.secondaryLabel.contains("+") ? neonGreenAccent : Color.HYPE.text.opacity(0.6)))
                    
                    // Bottom: Confidence + Trend
                    HStack(spacing: 4) {
                        Text(insight.confidenceLabel)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.HYPE.text.opacity(0.4))
                        
                        Spacer()
                        
                        Image(systemName: trendIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.HYPE.text.opacity(0.5))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Drawer Details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    Text(insight.explanation)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.HYPE.text.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                    
                    VStack(spacing: 8) {
                        ForEach(insight.details) { row in
                            HStack {
                                Text(row.key)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.HYPE.primary.opacity(0.7))
                                Spacer()
                                Text(row.value)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.HYPE.text.opacity(0.9))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .background(Color.black.opacity(0.2))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isExpanded ? strengthColor.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

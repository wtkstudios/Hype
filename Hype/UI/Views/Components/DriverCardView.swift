import SwiftUI

struct DriverCardView: View {
    let insight: DriverInsight
    let isTopDriver: Bool
    var onExpand: (() -> Void)? = nil
    
    @State private var isExpanded = false
    
    // Custom neon accents
    private let neonGreenAccent = Color.HYPE.tea
    private let neonRedAccent = Color.HYPE.neonRed
    
    private var strengthColor: Color {
        switch insight.strength {
        case .strong: return neonGreenAccent
        case .good: return Color.HYPE.tea
        case .neutral: return Color.HYPE.primary.opacity(0.6)
        case .weak: return neonRedAccent
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Card Content (Tappable)
            Button(action: {
                // Haptic feedback & Animation
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    // Slight delay to allow layout to compute new size before scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onExpand?()
                    }
                }
            }) {
                VStack(alignment: .leading, spacing: 14) {
                    // Top Row: Title + Strength Pill
                    HStack(alignment: .top) {
                        let dynamicTitle = insight.kind == .acceleration ? "ACCELERATION" : insight.kind.rawValue.uppercased()
                        Text(dynamicTitle)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color.HYPE.text.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70) // Allow slightly more shrinking if needed
                            .allowsTightening(true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Top Driver Badge + Strength Pill
                        HStack(spacing: 6) {
                            Text(insight.strength.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(strengthColor)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(strengthColor.opacity(0.15))
                                .cornerRadius(4)
                                .layoutPriority(1)
                        }
                    }
                    
                    // Middle Row: Big Metric
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.metricValue)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Color.HYPE.text)
                        
                        Text(insight.metricLabel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.HYPE.primary.opacity(0.8))
                    }
                    
                    // Below: Primary & Secondary Labels
                    VStack(alignment: .leading, spacing: 4) {
                        let bottomLabel = insight.relativeStatusText ?? insight.secondaryLabel
                        
                        Text(bottomLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(bottomLabel.contains("Below") || bottomLabel.contains("Falling") ? neonRedAccent : (bottomLabel.contains("Above") || bottomLabel.contains("Rising") ? neonGreenAccent : Color.HYPE.text.opacity(0.6)))
                    }
                    
                    Spacer(minLength: 0) // Push bottom row down evenly
                    
                    // Bottom: Chevron Only
                    HStack(spacing: 4) {
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.HYPE.text.opacity(0.6))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: .infinity, alignment: .topLeading)
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
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.8))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.2))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Subtle 1px ring vs thick glowing shadow when expanded
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isTopDriver ? neonGreenAccent.opacity(0.4) : (isExpanded ? strengthColor.opacity(0.15) : Color.white.opacity(0.05)), lineWidth: 1)
        )
        // Additional subtle outer notch/glow for top driver exclusively
        .shadow(color: isTopDriver ? neonGreenAccent.opacity(0.05) : Color.clear, radius: 4)
        // Add subtle scale down on press via ScaleButtonStyle if isolated, or implicit tap scale
        // handled natively by the OS PlainButtonStyle on some configurations, but let's enforce a generic slight scale wrapper:
    }
}

import SwiftUI

/// Live totals hero strip with count-up animations
struct HeroMetricStripView: View {
    let metrics: AccountMetrics
    
    @State private var animatedFollowers: Int = 0
    @State private var animatedLikes: Int = 0
    @State private var animatedComments: Int = 0
    @State private var animatedShares: Int = 0
    @State private var animatedViews: Int = 0
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 0) {
            HeroKPIBlock(label: "FOLLOWERS", value: animatedFollowers, targetValue: metrics.followers)
            heroDivider
            HeroKPIBlock(label: "LIKES", value: animatedLikes, targetValue: metrics.totalLikes)
            heroDivider
            HeroKPIBlock(label: "COMMENTS", value: animatedComments, targetValue: metrics.totalComments)
            heroDivider
            HeroKPIBlock(label: "SHARES", value: animatedShares, targetValue: metrics.totalShares)
            heroDivider
            HeroKPIBlock(label: "VIEWS", value: animatedViews, targetValue: metrics.totalViews)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.HYPE.primary.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            guard !appeared else { return }
            appeared = true
            // Staggered count-up animations
            animateCountUp(from: 0, to: metrics.followers, duration: 0.8) { animatedFollowers = $0 }
            animateCountUp(from: 0, to: metrics.totalLikes, duration: 0.9) { animatedLikes = $0 }
            animateCountUp(from: 0, to: metrics.totalComments, duration: 0.85) { animatedComments = $0 }
            animateCountUp(from: 0, to: metrics.totalShares, duration: 0.75) { animatedShares = $0 }
            animateCountUp(from: 0, to: metrics.totalViews, duration: 1.0) { animatedViews = $0 }
        }
    }
    
    private var heroDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(width: 1, height: 32)
    }
    
    /// Smooth count-up animation using a display-link-style timer
    private func animateCountUp(from: Int, to: Int, duration: Double, update: @escaping (Int) -> Void) {
        let steps = 30
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Double(i) / Double(steps)
                // Ease-out cubic
                let eased = 1.0 - pow(1.0 - progress, 3)
                let current = Int(Double(from) + (Double(to - from) * eased))
                withAnimation(.linear(duration: stepDuration * 0.8)) {
                    update(current)
                }
                
                // Final step → haptic
                if i == steps {
                    let impact = UIImpactFeedbackGenerator(style: .soft)
                    impact.impactOccurred(intensity: 0.5)
                }
            }
        }
    }
}

/// Individual KPI block in the hero strip
struct HeroKPIBlock: View {
    let label: String
    let value: Int
    let targetValue: Int
    
    @State private var glowOpacity: Double = 0
    @State private var scaleAmt: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 3) {
            Text(NumberFormatterUtils.formatCompact(number: value))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
                .scaleEffect(scaleAmt)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.HYPE.tea.opacity(glowOpacity))
                        .blur(radius: 8)
                        .allowsHitTesting(false)
                )
                .contentTransition(.numericText())
            
            Text(label)
                .font(.system(size: 7, weight: .heavy))
                .foregroundColor(Color.HYPE.text.opacity(0.35))
                .kerning(0.3)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: value) { newVal in
            // Milestone check — pop scale on round number thresholds
            if isMilestone(newVal) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    scaleAmt = 1.06
                    glowOpacity = 0.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        scaleAmt = 1.0
                        glowOpacity = 0
                    }
                }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
        }
    }
    
    private func isMilestone(_ val: Int) -> Bool {
        // Trigger on every 10% of target value reached
        let step = max(targetValue / 10, 1)
        return val > 0 && val % step == 0
    }
}

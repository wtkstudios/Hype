import SwiftUI

/// Circular ring showing Hype Health Score 0–100
struct HypeHealthRingView: View {
    let score: Int
    
    @State private var animatedProgress: CGFloat = 0
    @State private var glowOpacity: Double = 0.1
    
    private var progress: CGFloat {
        CGFloat(score) / 100.0
    }
    
    private var ringColor: Color {
        if score >= 80 { return Color.HYPE.tea }
        if score >= 50 { return Color(hex: "E6A23C").opacity(0.8) }
        return Color(hex: "C0392B").opacity(0.7)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("HYPE HEALTH")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .kerning(0.8)
            
            ZStack {
                // Track ring
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .shadow(color: ringColor.opacity(glowOpacity), radius: 6)
                
                // Score text
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(Color.HYPE.text)
                    Text("/ 100")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.35))
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = progress
                }
                // Subtle glow pulse
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.25
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

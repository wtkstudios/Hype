import SwiftUI

struct MoversCardStyle: ButtonStyle {
    let phaseColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(phaseColor.opacity(configuration.isPressed ? 0.18 : 0.0), lineWidth: 2)
            )
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
    }
}

struct MoversCardView: View {
    let post: TerminalPost
    
    var metricColor: Color {
        let acc = post.acceleration ?? 0
        return acc >= 0 ? Color.HYPE.neonGreen : Color.HYPE.neonRed
    }
    
    var body: some View {
        Button(action: {
            // Navigate to Post Detail Simulator
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        SwiftUI.Circle()
                            .fill(Color.HYPE.text.opacity(0.1))
                            .frame(width: 24, height: 24)
                            .overlay(Text(post.creatorHandle.prefix(2).uppercased()).font(.system(size: 8, weight: .bold)).foregroundColor(Color.HYPE.text))
                        
                        Text(post.creatorHandle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.HYPE.text)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.HYPE.text.opacity(0.3))
                }
                
                // Content
                Text(post.title ?? "Untitled")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.8))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Metrics Bottom
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SCORE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text.opacity(0.5))
                        Text(String(format: "%.1f", post.hypeScore))
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(Color.HYPE.text)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACCEL")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text.opacity(0.5))
                        HStack(spacing: 2) {
                            Text(String(format: "%.1f", post.acceleration ?? 0))
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(metricColor)
                            Image(systemName: (post.acceleration ?? 0) >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(metricColor)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .frame(width: 260)
            .background(Color.HYPE.base)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.HYPE.text.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(MoversCardStyle(phaseColor: post.phase.color))
    }
}

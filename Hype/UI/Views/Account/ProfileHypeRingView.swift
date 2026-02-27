import SwiftUI

/// "Orbital Identity" — user profile picture fused inside the animated Hype Health radial ring.
struct ProfileHypeRingView: View {
    let score: Int
    let profileImageURL: String
    
    @State private var animatedProgress: CGFloat = 0
    @State private var glowOpacity: Double = 0.08
    @State private var innerGlowOpacity: Double = 0
    
    private let ringSize: CGFloat = 200
    private let ringLineWidth: CGFloat = 8
    private let photoSize: CGFloat = 140
    
    private var progress: CGFloat {
        CGFloat(score) / 100.0
    }
    
    private var ringColor: Color {
        if score >= 80 { return Color.HYPE.tea }
        if score >= 50 { return Color(hex: "E6A23C").opacity(0.8) }
        return Color(hex: "C0392B").opacity(0.7)
    }
    
    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                ringColor.opacity(0.4),
                ringColor,
                ringColor
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * Double(progress))
        )
    }
    
    var body: some View {
        ZStack {
                // Background ambient glow
                Circle()
                    .fill(ringColor.opacity(glowOpacity * 0.3))
                    .frame(width: ringSize + 30, height: ringSize + 30)
                    .blur(radius: 20)
                
                // Track ring (background)
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: ringLineWidth)
                    .frame(width: ringSize, height: ringSize)
                
                // Animated progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
                    .shadow(color: ringColor.opacity(glowOpacity), radius: 10)
                
                // Inner dark border ring (creates depth between ring and photo)
                Circle()
                    .stroke(Color.HYPE.base.opacity(0.9), lineWidth: 8)
                    .frame(width: photoSize + 10, height: photoSize + 10)
                
                // Profile Picture
                AsyncImage(url: URL(string: profileImageURL)) { phase in
                    switch phase {
                    case .empty, .failure:
                        // Premium gradient placeholder
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.HYPE.primary.opacity(0.6),
                                    Color.HYPE.tea.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: photoSize, height: photoSize)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.4))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: photoSize, height: photoSize)
                            .clipShape(Circle())
                    @unknown default:
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: photoSize, height: photoSize)
                    }
                }
                .overlay(
                    // Subtle inner vignette
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.clear,
                                    Color.clear,
                                    Color.black.opacity(0.15)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .frame(width: photoSize, height: photoSize)
                )
                
                // Score badge (bottom-right of ring)
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(score)")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(Color.HYPE.text)
                        Text("/100")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text.opacity(0.4))
                    }
                    Text("OVERALL")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                        .kerning(0.5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.HYPE.base)
                        .overlay(
                            Capsule()
                                .stroke(ringColor.opacity(0.4), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 2)
                .offset(x: ringSize * 0.36, y: ringSize * 0.30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
            // Breathing glow
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.35
            }
            // Subtle inner fade-in
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                innerGlowOpacity = 1
            }
        }
        .frame(maxWidth: .infinity)
    }
}

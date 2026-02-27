import SwiftUI

struct DeparturesBoardRow: View {
    let post: TerminalPost
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPulsing = false
    
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: post.postedAt, relativeTo: Date())
    }
    
    var isAccelerating: Bool {
        return (post.acceleration ?? 0) > 5.0 // threshold
    }
    
    var body: some View {
        Button(action: {
            // Simulated navigation to PostDetail
        }) {
            HStack(spacing: 12) {
                // Avatar Placeholder
                SwiftUI.Circle()
                    .fill(Color.HYPE.text.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(Text(post.creatorHandle.prefix(2).uppercased()).font(.system(size: 10, weight: .bold)).foregroundColor(Color.HYPE.text))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(post.creatorHandle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.HYPE.text)
                        Text(timeAgoString)
                            .font(.system(size: 12))
                            .foregroundColor(Color.HYPE.text.opacity(0.5))
                    }
                    
                    Text(post.title ?? "Untitled")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.HYPE.text.opacity(0.8))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 12)
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        if isAccelerating {
                            SwiftUI.Circle()
                                .fill(Color.HYPE.neonGreen)
                                .frame(width: 4, height: 4)
                                .scaleEffect(isPulsing ? 1.05 : 0.9)
                                .opacity(isPulsing ? 1.0 : 0.6)
                                .shadow(color: Color.HYPE.neonGreen.opacity(0.5), radius: isPulsing ? 3 : 0)
                        }
                        PhasePillView(phase: post.phase)
                    }
                    
                    HStack(spacing: 8) {
                        if let vpm = post.vpm {
                            HStack(spacing: 2) {
                                Text("\(Int(vpm)) VPM")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.HYPE.text.opacity(0.7))
                                
                                if let accel = post.acceleration {
                                    Image(systemName: accel > 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(accel > 0 ? Color.HYPE.neonGreen : Color.HYPE.neonRed)
                                }
                            }
                        }
                        
                        if let prob = post.breakoutProb {
                            Text("\(Int(prob * 100))% BRK")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.HYPE.primary)
                        }
                    }
                }
                .frame(width: 110, alignment: .trailing)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.HYPE.text.opacity(0.3))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.HYPE.base)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.HYPE.text.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isAccelerating && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}

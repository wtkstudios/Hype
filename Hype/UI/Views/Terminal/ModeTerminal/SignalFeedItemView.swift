import SwiftUI

struct SignalFeedItemView: View {
    let event: TerminalSignalEvent
    let isNew: Bool // true if index == 0
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var scanlineOffset: CGFloat = -1.0
    @State private var showScanline = false
    @State private var hasAppeared = false
    
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: event.timestamp, relativeTo: Date())
    }
    
    var colorForEvent: Color {
        switch event.eventType {
        case .enteredExpanding: return Color.HYPE.tea
        case .enteredBreakout: return Color.HYPE.tangerine
        case .plateaued: return Color.HYPE.text.opacity(0.5)
        case .reignited: return Color.HYPE.error
        case .velocityDip: return Color.HYPE.error
        case .spike: return Color.HYPE.tea
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Signal Dot
            SwiftUI.Circle()
                .fill(colorForEvent)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.creatorHandle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                    Text(timeAgoString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                }
                
                Text(event.eventType.signalDescription)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.8))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.HYPE.text.opacity(0.03))
        .cornerRadius(8)
        .overlay(
            GeometryReader { geo in
                if showScanline {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, colorForEvent.opacity(0.2), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.4)
                        .offset(x: geo.size.width * scanlineOffset)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        )
        // Slide in animation modifiers
        .opacity(hasAppeared ? 1.0 : (isNew && !reduceMotion ? 0.0 : 1.0))
        .offset(y: hasAppeared ? 0 : (isNew && !reduceMotion ? -8 : 0))
        .onAppear {
            if isNew && !reduceMotion && !hasAppeared {
                // Slide/Fade in
                withAnimation(.easeOut(duration: 0.3)) {
                    hasAppeared = true
                }
                // Scanline sweep
                showScanline = true
                withAnimation(.linear(duration: 0.45).delay(0.1)) {
                    scanlineOffset = 2.0
                }
                // Cleanup
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showScanline = false
                }
            } else {
                hasAppeared = true
            }
        }
    }
}

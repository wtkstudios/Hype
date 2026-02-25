import SwiftUI

struct IntelligenceDashboardView: View {
    let mockWindows = PredictiveEngine.shared.generatePostingWindows(for: BaselineProfile(id: "1", accountId: "1", computedAt: Date(), windowDays: 30))
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.HYPE.base.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                        contentFatigueAlert
                        predictiveWindowsList
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("INTELLIGENCE")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
            
            Spacer()
        }
    }
    
    private var contentFatigueAlert: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.HYPE.error)
                Text("CONTENT FATIGUE WARNING")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Color.HYPE.error)
            }
            
            Text("Your last 3 videos in the 'Vlog' format have underperformed baseline by 40%. The algorithm is suppressing repetitive structures. We recommend switching to 'Tutorial' format for the next post.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.HYPE.text.opacity(0.8))
                .lineSpacing(4)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.error.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var predictiveWindowsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PREDICTED OPTIMAL WINDOWS")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            VStack(spacing: 16) {
                ForEach(Array(mockWindows.enumerated()), id: \.offset) { index, window in
                    windowCard(for: window, isTop: index == 0)
                }
            }
        }
    }
    
    private func windowCard(for window: PredictiveEngine.BestPostingWindow, isTop: Bool) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .center, spacing: 4) {
                Text(window.startTime, format: .dateTime.hour().minute())
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
                
                Text("TO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                
                Text(window.endTime, format: .dateTime.hour().minute())
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
            }
            .frame(width: 80)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if isTop {
                        Text("PRIME")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.HYPE.primary)
                            .foregroundColor(Color.HYPE.base)
                            .cornerRadius(4)
                    }
                    
                    Text("\(Int(window.confidenceScore * 100))% CONVICTION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.7))
                }
                
                Text(window.reason)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isTop ? Color.HYPE.primary.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                
                if isTop {
                    // Pen markup underline simulated
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.HYPE.tangerine.opacity(0.8)) // Strict constraint: Tangerine allowed for single marker highlight
                            .frame(width: 60, height: 3)
                            .rotationEffect(.degrees(-2))
                            .offset(x: 0, y: 1)
                    }
                }
            }
        )
    }
}

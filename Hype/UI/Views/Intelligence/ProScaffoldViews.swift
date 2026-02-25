import SwiftUI

struct ComparePostsView: View {
    var body: some View {
        ZStack {
            Color.HYPE.base.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 64))
                    .foregroundColor(Color.HYPE.primary)
                
                Text("COMPARE POSTS")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
                
                Text("Overlay velocities and extract winning hook formulas across your top performing videos.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    Task { try? await SubscriptionManager.shared.purchasePro() }
                }) {
                    Text("Unlock HYPE PRO")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.HYPE.base)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.HYPE.text)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklyBriefView: View {
    var body: some View {
        ZStack {
            Color.HYPE.base.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 64))
                    .foregroundColor(Color.HYPE.primary)
                
                Text("THE WEEKLY BRIEF")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
                
                Text("Automated PDF summaries analyzing your 7-day performance curve, sent straight to your agency team.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    Task { try? await SubscriptionManager.shared.purchasePro() } // In real routing this hooks to Agency tier
                }) {
                    Text("Unlock HYPE AGENCY")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.HYPE.base)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.HYPE.text)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

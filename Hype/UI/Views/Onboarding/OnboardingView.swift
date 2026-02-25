import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: TikTokAuthViewModel
    
    var body: some View {
        ZStack {
            Color.HYPE.base.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Hero Header
                VStack(spacing: 16) {
                    Text("HYPE")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundColor(Color.HYPE.text)
                    
                    Text("Measure the Moment")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                        .kerning(2)
                }
                
                // Value Props
                VStack(alignment: .leading, spacing: 24) {
                    valuePropRow(icon: "chart.line.uptrend.xyaxis", text: "Predict viral momentum before it happens.")
                    valuePropRow(icon: "bell.badge.fill", text: "Get alerts when a video breaks baseline.")
                    valuePropRow(icon: "sparkles", text: "Turn views into actionable insights.")
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                
                Spacer()
                
                // Connect Action
                VStack(spacing: 16) {
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.HYPE.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Button(action: {
                        authViewModel.login()
                    }) {
                        HStack {
                            if authViewModel.isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.HYPE.base))
                            } else {
                                Image(systemName: "link")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Connect TikTok")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(Color.HYPE.base)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.HYPE.text)
                        .cornerRadius(12)
                    }
                    .disabled(authViewModel.isAuthenticating)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    Text("By connecting, you agree to our Terms & Privacy Policy.")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
    
    private func valuePropRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color.HYPE.energy)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.9))
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(TikTokAuthViewModel())
}

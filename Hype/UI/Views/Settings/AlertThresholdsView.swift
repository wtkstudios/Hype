import SwiftUI

struct AlertThresholdsView: View {
    @State private var momentumSpikeThreshold: Double = 1.2
    @State private var underperformThreshold: Double = 0.5
    @State private var receiveDailyDigest = true
    @State private var enableQuietHours = false
    @State private var quietHoursStart = Date()
    @State private var quietHoursEnd = Date()
    
    var body: some View {
        ZStack {
            Color.HYPE.base.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("ALERT TUNING")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(Color.HYPE.text)
                    
                    Text("Adjust the sensitivity of HYPE's detection engine. Lowering thresholds increases alert frequency.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.bottom, 8)
                    
                    thresholdSlider(
                        title: "Momentum Spike Sensitivity",
                        value: $momentumSpikeThreshold,
                        range: 1.0...2.0,
                        step: 0.1,
                        format: "%.1fx Baseline",
                        meaning: "Triggers when velocity ≥ \(String(format: "%.1f", momentumSpikeThreshold))x baseline for ≥ 2 intervals"
                    )
                    
                    thresholdSlider(
                        title: "Underperform Drop-off",
                        value: $underperformThreshold,
                        range: 0.1...0.9,
                        step: 0.1,
                        format: "%.1fx Baseline",
                        meaning: "Triggers when velocity ≤ \(String(format: "%.1f", underperformThreshold))x baseline after 15 min"
                    )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DELIVERY PREFERENCES")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.HYPE.text.opacity(0.5))
                        
                        Toggle("Daily Digest Summary", isOn: $receiveDailyDigest)
                            .tint(Color.HYPE.primary)
                            .foregroundColor(Color.HYPE.text)
                        
                        Toggle("Quiet Hours", isOn: $enableQuietHours)
                            .tint(Color.HYPE.primary)
                            .foregroundColor(Color.HYPE.text)
                        
                        if enableQuietHours {
                            VStack(spacing: 12) {
                                DatePicker("Start Time", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                                    .foregroundColor(Color.HYPE.text.opacity(0.8))
                                
                                DatePicker("End Time", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                                    .foregroundColor(Color.HYPE.text.opacity(0.8))
                                
                                Text("Only Critical alerts will bypass Quiet Hours.")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Thresholds")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func thresholdSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double.Stride, format: String, meaning: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.energy)
            }
            
            Slider(value: value, in: range, step: step)
                .accentColor(Color.HYPE.primary) // Strict constraint: active track must use Lavender, not Tangerine.
            
            Text(meaning)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.HYPE.text.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

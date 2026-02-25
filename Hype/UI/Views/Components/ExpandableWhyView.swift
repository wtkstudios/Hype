import SwiftUI

struct ExpandableWhyView: View {
    let drivers: [DriverItem]
    let confidence: Double
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("WHY THIS ACTION?")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("CONFIDENCE: \(Int(confidence * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(confidence > 0.8 ? Color.HYPE.tea : Color.HYPE.text.opacity(0.6))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.HYPE.primary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(drivers.enumerated()), id: \.offset) { _, driver in
                        HStack(spacing: 12) {
                            // Impact Dot
                            Circle()
                                .fill(driver.impact == "Positive" ? Color.HYPE.tea : (driver.impact == "Negative" ? Color.HYPE.error : Color.HYPE.primary))
                                .frame(width: 6, height: 6)
                            
                            Text(driver.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.HYPE.text.opacity(0.8))
                            
                            Spacer()
                            
                            Text(driver.delta)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.HYPE.text)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(6)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

import SwiftUI

struct MemberRowView: View {
    let member: CircleMember
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Circle()
                .fill(Color.HYPE.text.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(Text(member.handle.prefix(2).uppercased()).font(.system(size: 12, weight: .bold)).foregroundColor(Color.HYPE.text))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.handle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                
                if !member.isConnected {
                    Text("Not connected")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.HYPE.error)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.HYPE.error.opacity(0.15))
                        .cornerRadius(4)
                } else if let score = member.overallScore {
                    HStack(spacing: 4) {
                        Text("Overall:")
                            .font(.system(size: 12))
                            .foregroundColor(Color.HYPE.text.opacity(0.6))
                        Text("\(Int(score))")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text)
                    }
                }
            }
            
            Spacer()
            
            if member.isConnected, let trend = member.trend7d {
                HStack(spacing: 2) {
                    Text(trend > 0 ? "+\(Int(trend))" : "\(Int(trend))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(trend > 0 ? Color.HYPE.neonGreen : Color.HYPE.neonRed)
                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trend > 0 ? Color.HYPE.neonGreen : Color.HYPE.neonRed)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

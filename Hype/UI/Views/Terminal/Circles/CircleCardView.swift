import SwiftUI

struct CircleCardView: View {
    let circle: HypeCircle
    let activeTrainsCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(circle.name)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Color.HYPE.text)
                Spacer()
                if circle.isInviteOnly {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                }
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MEMBERS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                    Text("\(circle.memberIds.count)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE TRAINS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                    Text("\(activeTrainsCount)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.primary)
                }
            }
        }
        .padding(16)
        .background(Color.HYPE.base)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.HYPE.text.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(16)
        .frame(width: 240)
    }
}

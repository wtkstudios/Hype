import SwiftUI

struct CircleDetailView: View {
    let circle: HypeCircle
    @ObservedObject var dataService: TerminalDataService
    
    let mockMembers = [
        CircleMember(id: "c1", handle: "@alex", avatarURL: nil, isConnected: true, overallScore: 84.5, trend7d: 5.2),
        CircleMember(id: "c2", handle: "@sam", avatarURL: nil, isConnected: true, overallScore: 92.0, trend7d: 12.0),
        CircleMember(id: "c3", handle: "@jordan", avatarURL: nil, isConnected: false, overallScore: nil, trend7d: nil)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    statBox(title: "AVG OVERALL", value: "88")
                    statBox(title: "EXPANDING", value: "2")
                    statBox(title: "BREAKOUT", value: "1")
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("MEMBERS")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(mockMembers) { member in
                            MemberRowView(member: member)
                                .padding(.horizontal)
                            Divider()
                                .background(Color.HYPE.text.opacity(0.1))
                                .padding(.horizontal)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("CIRCLE TRACK BOARD")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(dataService.circlePosts) { post in
                            DeparturesBoardRow(post: post)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(Color.HYPE.base)
        .navigationTitle(circle.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Color.HYPE.text.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.HYPE.text.opacity(0.05))
        .cornerRadius(8)
    }
}

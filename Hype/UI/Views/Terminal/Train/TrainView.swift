import SwiftUI

struct TrainView: View {
    @ObservedObject var dataService: TerminalDataService
    let scope: TerminalScope
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TracksVisualizationView(activePosts: dataService.filteredPosts(scope: scope))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEPARTURES")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        let posts = dataService.filteredPosts(scope: scope)
                        ForEach(posts, id: \.id) { post in
                            // Simulating navigation to a PostDetail screen logic here
                            DeparturesBoardRow(post: post)
                                .padding(.horizontal)
                        }
                        
                        if dataService.circlePosts.isEmpty {
                            Text("No recent departures")
                                .font(.system(size: 14))
                                .foregroundColor(Color.HYPE.text.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(Color.HYPE.base)
    }
}

import SwiftUI

struct AllPostsListView: View {
    // We will inject the view model data here.
    let viewModel: DashboardViewModel
    
    @State private var selectedPhase: DistributionPhase? = nil // nil means "All"
    
    // Mock list of all posts for demonstration
    var allPosts: [VideoCardData] {
        return [
            viewModel.mockVideo1,
            viewModel.mockVideo2,
            viewModel.mockVideo3,
            VideoCardData(id: "4", title: "Day In The Life", score: 88.5, phase: .expanding, delta: "+22%"),
            VideoCardData(id: "5", title: "Behind The Scenes", score: 62.1, phase: .plateau, delta: "-5%"),
            VideoCardData(id: "6", title: "Q&A Setup", score: 35.0, phase: .testing, delta: "+4%")
        ]
    }
    
    var filteredPosts: [VideoCardData] {
        if let phase = selectedPhase {
            return allPosts.filter { $0.phase == phase }
        }
        return allPosts
    }
    
    var body: some View {
        ZStack {
            Color.HYPE.base.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                filterHeader
                Divider().background(Color.white.opacity(0.1))
                postsList
            }
        }
        .navigationTitle("All Posts")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var filterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: "All", isSelected: selectedPhase == nil) {
                    selectedPhase = nil
                }
                
                ForEach([DistributionPhase.expanding, DistributionPhase.testing, DistributionPhase.plateau], id: \.self) { phase in
                    FilterPill(title: phase.rawValue.capitalized, isSelected: selectedPhase == phase) {
                        selectedPhase = phase
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.02))
    }
    
    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPosts, id: \.id) { video in
                    NavigationLink(destination: PostDetailView(video: video)) {
                        PostListItem(video: video)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

// Subcomponents

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.HYPE.primary : Color.white.opacity(0.1))
                .foregroundColor(isSelected ? Color.HYPE.base : Color.HYPE.text)
                .cornerRadius(20)
        }
    }
}

struct PostListItem: View {
    let video: VideoCardData
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail placeholder
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(Color.white.opacity(0.3))
                )
                .frame(width: 60, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(video.phase.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(Color.HYPE.text)
                        .cornerRadius(4)
                    
                    Text(video.delta)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(video.delta.hasPrefix("+") ? Color.HYPE.primary : Color.HYPE.text.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "%.1f", video.score))
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(Color.HYPE.text)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.3))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

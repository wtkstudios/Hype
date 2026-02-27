import SwiftUI

struct TerminalModeView: View {
    @ObservedObject var dataService: TerminalDataService
    let scope: TerminalScope
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Top Movers
                VStack(alignment: .leading, spacing: 12) {
                    Text("TOP MOVERS")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            let movers = topMovers()
                            if movers.isEmpty {
                                EmptyStateCard(title: "No momentum data", subtitle: "Switch circle scope or post content.", actionText: nil)
                                    .padding(.horizontal)
                            } else {
                                ForEach(movers, id: \.id) { post in
                                    MoversCardView(post: post)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // Watchlist & Radar
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BREAKOUT WATCHLIST")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text.opacity(0.6))
                        
                        let watchlist = getWatchlist()
                        if watchlist.isEmpty {
                            EmptyStateCard(title: "No breakouts on watchlist", subtitle: "Try switching circle scope or lowering threshold.", actionText: "Lower threshold")
                        } else {
                            ForEach(watchlist, id: \.id) { post in
                                WatchlistCardView(post: post)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RE-IGNITE RADAR")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text.opacity(0.6))
                        
                        let radar = getRadar()
                        if radar.isEmpty {
                            EmptyStateCard(title: "Radar clear", subtitle: "No recent plateau drop-offs.", actionText: nil)
                        } else {
                            ForEach(radar, id: \.id) { post in
                                RadarCardView(post: post)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Signal Feed
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("SIGNAL FEED")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text.opacity(0.6))
                        Spacer()
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color.HYPE.neonGreen)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 1) {
                        let signals = dataService.filteredSignals(scope: scope)
                        if signals.isEmpty {
                            Text("Awaiting signals...")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(Color.HYPE.text.opacity(0.4))
                                .padding()
                        } else {
                            ForEach(Array(signals.enumerated()), id: \.element.id) { index, signal in
                                SignalFeedItemView(event: signal, isNew: index == 0)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Helpers
    
    private func topMovers() -> [TerminalPost] {
        return dataService.filteredPosts(scope: scope).sorted { ($0.acceleration ?? 0) > ($1.acceleration ?? 0) }.prefix(3).map { $0 }
    }
    
    private func getWatchlist() -> [TerminalPost] {
        return dataService.filteredPosts(scope: scope).filter { $0.phase == .expanding && ($0.breakoutProb ?? 0) > 0.6 }
    }
    
    private func getRadar() -> [TerminalPost] {
        return dataService.filteredPosts(scope: scope).filter { $0.phase == .reignite }
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String
    let actionText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.6))
                .lineLimit(nil)
            Text(subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .lineLimit(nil)
            
            if let actionText = actionText {
                Button(action: {}) {
                    Text(actionText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.HYPE.text.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.text.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
        .cornerRadius(12)
    }
}

// Breaking out the view builder functions into standalone structs so they can be identified
struct WatchlistCardView: View {
    let post: TerminalPost
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.creatorHandle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                Spacer()
                Text("HYPE \(Int(post.hypeScore))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
            }
            Text("Projected next: Breakout (\(Int((post.breakoutProb ?? 0) * 100))%)")
                .font(.system(size: 12))
                .foregroundColor(Color.HYPE.neonGreen)
            Text("Action: Reply to top comment / Pin follow-up / Post part 2")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.HYPE.text.opacity(0.8))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.HYPE.text.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.text.opacity(0.1), lineWidth: 1)
        )
    }
}

struct RadarCardView: View {
    let post: TerminalPost
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.creatorHandle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                Spacer()
            }
            Text("Secondary push detected")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.HYPE.neonRed)
            Text("Recommendation: Capitalize with a stitch or duet immediately.")
                .font(.system(size: 12))
                .foregroundColor(Color.HYPE.text.opacity(0.8))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.HYPE.text.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.text.opacity(0.1), lineWidth: 1)
        )
    }
}

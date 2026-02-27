import SwiftUI

/// My Circle — the personal social momentum layer
struct MyCircleView: View {
    @ObservedObject var dataService: TerminalDataService
    @State private var showAddMember = false
    @State private var searchHandle = ""
    
    private let circlePosts: [TerminalPost] = []
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Circle Overview Strip
                circleOverviewStrip
                
                // Today's Momentum Hero
                todaysMomentumSection
                
                // Breakout Watchlist
                breakoutWatchlist
                
                // Circle Feed
                circleFeedSection
                
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(Color.HYPE.base)
    }
    
    // MARK: - Overview Strip
    
    private var circleOverviewStrip: some View {
        HStack(spacing: 0) {
            overviewBlock(label: "MEMBERS", value: "\(totalMembers())")
            divider
            overviewBlock(label: "ACTIVE TODAY", value: "\(activeTodayCount())")
            divider
            overviewBlock(label: "EXPANDING", value: "\(expandingCount())")
            divider
            overviewBlock(label: "BREAKOUT", value: "\(breakoutCount())", highlight: breakoutCount() > 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.primary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private func overviewBlock(label: String, value: String, highlight: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(highlight ? Color.HYPE.tea : Color.HYPE.text)
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 28)
    }
    
    // MARK: - Today's Momentum
    
    private var todaysMomentumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "TODAY'S MOMENTUM", subtitle: "Top mover in your Circle")
            
            if let topMover = dataService.circleTopMover {
                MomentumSpotlightCard(post: topMover, dataService: dataService)
                    .padding(.horizontal)
            } else {
                EmptyStateCard(title: "No movers yet", subtitle: "Invite creators to your Circle to see live momentum.", actionText: nil)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Breakout Watchlist
    
    private var breakoutWatchlist: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "BREAKOUT WATCHLIST", subtitle: "Close to breakout (>60% prob)")
            
            let watchlist = dataService.circleBreakoutWatchlist
            if watchlist.isEmpty {
                EmptyStateCard(title: "Watchlist clear", subtitle: "No posts near breakout threshold right now.", actionText: nil)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
                    ForEach(watchlist) { post in
                        WatchlistBoostCard(post: post, dataService: dataService)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Circle Feed
    
    private var circleFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "CIRCLE FEED", subtitle: "Recent moments")
            
            VStack(spacing: 1) {
                if dataService.momentFeed.isEmpty {
                    EmptyStateCard(title: "Quiet circle", subtitle: "Moments appear when your circle posts go live.", actionText: nil)
                        .padding(.horizontal)
                } else {
                    ForEach(dataService.momentFeed) { moment in
                        MomentRowView(moment: moment)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(Color.HYPE.text.opacity(0.5))
                .kerning(0.8)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.HYPE.text.opacity(0.3))
        }
        .padding(.horizontal)
    }
    
    private func totalMembers() -> Int {
        let allMemberIds = Set(dataService.circles.flatMap { $0.memberIds })
        return allMemberIds.count
    }
    
    private func activeTodayCount() -> Int {
        let all = dataService.myPosts + dataService.circlePosts
        return all.filter { Calendar.current.isDateInToday($0.postedAt) || $0.postedAt > Date().addingTimeInterval(-86400) }.count
    }
    
    private func expandingCount() -> Int {
        (dataService.myPosts + dataService.circlePosts).filter { $0.phase == .expanding }.count
    }
    
    private func breakoutCount() -> Int {
        (dataService.myPosts + dataService.circlePosts).filter { $0.phase == .breakout }.count
    }
}

// MARK: - Spotlight Card

struct MomentumSpotlightCard: View {
    let post: TerminalPost
    @ObservedObject var dataService: TerminalDataService
    @State private var boostPressed = false
    
    private var accelArrow: String {
        guard let a = post.acceleration else { return "→" }
        if a > 20 { return "↑" }
        if a < -5 { return "↓" }
        return "→"
    }
    
    private var accelColor: Color {
        guard let a = post.acceleration else { return Color.HYPE.text.opacity(0.5) }
        if a > 20 { return Color.HYPE.tea }
        if a < -5 { return Color.HYPE.neonRed }
        return Color.HYPE.text.opacity(0.5)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Creator row
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.HYPE.primary.opacity(0.25))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(post.creatorHandle.prefix(2)).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.HYPE.primary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.creatorHandle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                    Text(post.title ?? "Untitled post")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Phase badge + accel arrow
                VStack(spacing: 4) {
                    Text(post.phase.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(post.phase.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(post.phase.color.opacity(0.15))
                        .cornerRadius(4)
                    
                    Text(accelArrow)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accelColor)
                }
            }
            
            // Score + breakout prob bar
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HYPE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                    Text(String(format: "%.1f", post.hypeScore))
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(Color.HYPE.text)
                }
                
                Spacer()
                
                if let prob = post.breakoutProb {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("BREAKOUT PROB")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(Color.HYPE.text.opacity(0.4))
                            Text("\(Int(prob * 100))%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.HYPE.tea)
                        }
                        
                        // Probability bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.HYPE.tea)
                                    .frame(width: geo.size.width * prob, height: 4)
                            }
                        }
                        .frame(width: 100, height: 4)
                    }
                }
            }
            
            // BOOST CTA
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                dataService.sendBoost(to: post)
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    boostPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    boostPressed = false
                }
                // Open TikTok — structured for real deeplink when wired up
                if let url = URL(string: "tiktok://") { UIApplication.shared.open(url) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("BOOST")
                        .font(.system(size: 12, weight: .black))
                        .kerning(0.5)
                }
                .foregroundColor(Color.HYPE.base)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.HYPE.tangerine)
                .cornerRadius(8)
                .scaleEffect(boostPressed ? 0.95 : 1.0)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.HYPE.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Watchlist Boost Card

struct WatchlistBoostCard: View {
    let post: TerminalPost
    @ObservedObject var dataService: TerminalDataService
    @State private var boosted = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Creator avatar
            Circle()
                .fill(Color.HYPE.primary.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(post.creatorHandle.prefix(2)).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(post.creatorHandle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                
                // Prob bar
                if let prob = post.breakoutProb {
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 3)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.HYPE.tea.opacity(0.7))
                                    .frame(width: geo.size.width * prob, height: 3)
                            }
                        }
                        .frame(height: 3)
                        
                        Text("\(Int(prob * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.tea)
                            .fixedSize()
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                dataService.sendBoost(to: post)
                withAnimation { boosted = true }
                if let url = URL(string: "tiktok://") { UIApplication.shared.open(url) }
            }) {
                Text(boosted ? "✓" : "BOOST")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(boosted ? Color.HYPE.tea : Color.HYPE.base)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(boosted ? Color.HYPE.tea.opacity(0.15) : Color.HYPE.tangerine)
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Moment Row View

struct MomentRowView: View {
    let moment: MomentEvent
    
    var body: some View {
        HStack(spacing: 10) {
            Text(moment.type.emoji)
                .font(.system(size: 16))
            
            HStack(spacing: 4) {
                Text(moment.creatorHandle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                Text(moment.type.label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
            }
            
            Spacer()
            
            Text(timeAgo(moment.timestamp))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.HYPE.text.opacity(0.3))
        }
        .padding(.vertical, 10)
        .overlay(Divider().opacity(0.08), alignment: .bottom)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let secs = -date.timeIntervalSinceNow
        if secs < 3600 { return "\(Int(secs / 60))m ago" }
        if secs < 86400 { return "\(Int(secs / 3600))h ago" }
        return "\(Int(secs / 86400))d ago"
    }
}

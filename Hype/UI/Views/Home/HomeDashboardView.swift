import SwiftUI
import Combine

struct DashboardViewModel {
    // MVP Mock Data for Initial UI Build
    var handle: String = "@creator"
    var profileImageURL: String = ""
    var followerCount: Int = 128400
    var totalLikes: Int = 4200000
    var totalComments: Int = 312500
    var hypeScore: Double = 84.2
    var momentumIndex: Int = 92
    var volatility: Double = 1.15
    let currentPhase = DistributionPhase.expanding
    let currentAction = RecommendedAction.respondToComment
    
    // Recent videos placeholder
    let mockVideo1 = VideoCardData(id: "1", title: "Waitlist Launch Hook", score: 84.2, phase: .expanding, delta: "+15%")
    let mockVideo2 = VideoCardData(id: "2", title: "Product Teaser", score: 55.0, phase: .plateau, delta: "-2%")
    let mockVideo3 = VideoCardData(id: "3", title: "Scrapbook Aesthetic", score: 42.1, phase: .testing, delta: "+1%")
}

struct VideoCardData: Identifiable {
    let id: String
    let title: String
    let score: Double
    let phase: DistributionPhase
    let delta: String
}

struct HomeDashboardView: View {
    let viewModel = DashboardViewModel()
    
    @State private var showingAddAccount = false
    @State private var showingNotifications = false
    @State private var navPath = NavigationPath()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                Color.HYPE.base.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        heroModule
                        actionTile
                        recentPostsSection
                        // suggestionsSection // This section is not defined in the original code, omitting for now.
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                if destination == "AccountDashboard" {
                    // Placeholder for AccountDashboardView.
                    // The original snippet had `AccountDashboardView(userId: viewModel.account?.id ?? "")`
                    // but viewModel does not have an `account` property.
                    // Assuming a simple placeholder for now.
                    Text("Account Dashboard View")
                        .navigationTitle("Account Dashboard")
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                // viewModel.fetchDashboardData() // This method is not defined in the original ViewModel.
            }
            .onReceive(timer) { _ in
                // Auto-refresh logic handled in ViewModel
            }
            .sheet(isPresented: $showingAddAccount) {
                // EnrollmentView() // This view is not defined in the original code.
                Text("Enrollment View")
            }
            .fullScreenCover(isPresented: $showingNotifications) {
                // Notifications view // This view is not defined in the original code.
                Text("Notifications View")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HYPE")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
                
                Spacer()
                
                // Account Switcher Placeholder
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.HYPE.primary)
                        .frame(width: 24, height: 24)
                    Text("@creator")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(100)
            }
            
            BlinkingMomentumIndicator(momentumIndex: viewModel.momentumIndex)
        }
    }
    
    private var heroModule: some View {
        VStack(spacing: 0) {
            // Top Stats Card (Tappable to Account Dashboard)
            Button(action: {
                navPath.append("AccountDashboard")
            }) {
                VStack(alignment: .leading, spacing: 16) {
                    // Row 1: 2-Column Grid Layout
                    HStack(alignment: .center) {
                        
                        // LEFT COLUMN: Identity
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .bottom, spacing: 12) {
                                AsyncImage(url: URL(string: viewModel.profileImageURL)) { phase in
                                    switch phase {
                                    case .empty, .failure:
                                        // Premium Gradient Placeholder
                                        Circle()
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [Color.HYPE.primary.opacity(0.8), Color.HYPE.tea.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 60, height: 60)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    @unknown default:
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                    }
                                }
                                .overlay(Circle().stroke(Color.HYPE.tea.opacity(0.3), lineWidth: 1))
                                
                                Text(viewModel.handle)
                                    .font(.system(size: 14, weight: .medium)) // Smaller username beside large image
                                    .foregroundColor(Color.HYPE.text)
                                    .padding(.bottom, 6)
                            }
                            
                            let followers = NumberFormatterUtils.formatCompact(number: viewModel.followerCount)
                            let likes = NumberFormatterUtils.formatCompact(number: viewModel.totalLikes)
                            let comments = NumberFormatterUtils.formatCompact(number: viewModel.totalComments)
                            
                            // Stacked Stats (Number Emphasis)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(followers).font(.system(size: 13, weight: .semibold)).foregroundColor(Color.HYPE.text.opacity(0.9))
                                    Text("Followers").font(.system(size: 12)).foregroundColor(Color.HYPE.text.opacity(0.7))
                                }
                                HStack(spacing: 8) {
                                    Text(likes).font(.system(size: 13, weight: .semibold)).foregroundColor(Color.HYPE.text.opacity(0.9))
                                    Text("Likes").font(.system(size: 12)).foregroundColor(Color.HYPE.text.opacity(0.7))
                                }
                                HStack(spacing: 8) {
                                    Text(comments).font(.system(size: 13, weight: .semibold)).foregroundColor(Color.HYPE.text.opacity(0.9))
                                    Text("Comments").font(.system(size: 12)).foregroundColor(Color.HYPE.text.opacity(0.7))
                                }
                            }
                        }
                        
                        Spacer(minLength: 16)
                        
                        // RIGHT COLUMN: Performance (Aligned Trailing)
                        VStack(alignment: .trailing, spacing: 8) {
                            // INDEX Block (Smaller, less dominant)
                            VStack(alignment: .trailing, spacing: -2) {
                                Text("INDEX")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(red: 0.8, green: 0.7, blue: 1.0)) // Lavender
                                    .kerning(1)
                                
                                Text("\(viewModel.momentumIndex)")
                                    .font(.system(size: 40, weight: .black)) // Scaled down 10-15%
                                    .foregroundColor(Color.HYPE.text)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            // Sparkline (with dynamic color resolver hook)
                            AccountTrendSparklineView()
                                .frame(width: 80, height: 24)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                            
                            // Muted Volatility Block
                            Text("\(String(format: "%.2f", viewModel.volatility)) Moderate Volatility")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.HYPE.text.opacity(0.6))
                        }
                        .padding(.trailing, 28) // Prevent chevron collision
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .overlay(
                    // Subtle chevron on the top right, clear of content
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.top, 16)
                        .padding(.trailing, 16),
                    alignment: .topTrailing
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Latest Post Card (Tappable to Post Detail)
            Button(action: {
                // Navigate to PostDetailView
            }) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("LATEST POST")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.HYPE.text.opacity(0.8))
                        Spacer()
                        Text("24m ago")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.HYPE.text.opacity(0.5))
                            .padding(.trailing, 28) // Prevent chevron collision
                    }
                    
                    // Main Content Columns
                    HStack(alignment: .bottom, spacing: 16) {
                        // LEFT CLUSTER
                        VStack(alignment: .leading, spacing: 18) {
                            // Score Block
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(String(format: "%.1f", viewModel.hypeScore))
                                        .font(.system(size: 70, weight: .black))
                                        .foregroundColor(Color.HYPE.text)
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false) // Prevent truncation in HStack
                                        .onAppear {
                                            // Simulated ticking haptic for when the score loads or updates
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.prepare()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                generator.impactOccurred()
                                            }
                                        }
                                        .background(
                                            Ellipse()
                                                .stroke(Color.HYPE.tea, lineWidth: 2) // Strict constraint: Use Tea for positive/stable decorative.
                                                .frame(width: 165, height: 85) // Encircle but keep tight
                                                .rotationEffect(.degrees(-6))
                                                .offset(x: 2, y: 2)
                                        )
                                    
                                    // Pulse Dot next to score
                                    Circle()
                                        .fill(Color.HYPE.tea)
                                        .frame(width: 8, height: 8)
                                        .opacity(0.8)
                                        .offset(y: 12)
                                }
                                
                                // Caption label
                                Text("HYPE SCORE")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(Color.HYPE.primary)
                                    .kerning(1)
                            }
                            
                            // Mini Metrics Row
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Velocity")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                                        .lineLimit(1)
                                    Text("High")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.HYPE.text)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Shares")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                                        .lineLimit(1)
                                    Text("12k")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.HYPE.text)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Comments")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text("4.5k")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.HYPE.text)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // RIGHT CLUSTER
                        VStack(alignment: .center, spacing: 14) {
                            // Graph
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 35))
                                path.addLine(to: CGPoint(x: 25, y: 30))
                                path.addLine(to: CGPoint(x: 50, y: 18))
                                path.addLine(to: CGPoint(x: 80, y: 5))
                            }
                            .stroke(GraphColorResolver.strokeColor(trend: .up), lineWidth: 3.5)
                            .shadow(color: GraphColorResolver.strokeColor(trend: .up).opacity(0.5), radius: 3, x: 0, y: 2)
                            .frame(width: 80, height: 40) // Match width of Account graph above for symmetry
                            
                            // Phase Block
                            VStack(alignment: .center, spacing: 6) {
                                HStack(spacing: 6) {
                                    Text("PHASE:")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                                        .fixedSize(horizontal: true, vertical: false)
                                        
                                    Text(viewModel.currentPhase.rawValue.uppercased())
                                        .font(.system(size: 8, weight: .black))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(Color.HYPE.primary)
                                        .foregroundColor(Color.HYPE.base)
                                        .cornerRadius(4)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                
                                Text("+15% VS BASELINE")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.HYPE.text.opacity(0.85))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.trailing, 14) // Offset for .center alignment to maintain perfect graph edge symmetry
                        .padding(.bottom, 2)
                    }
                    .padding(.top, 16)
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .overlay(
                    // Subtle chevron on the top right, clear of content
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.top, 16)
                        .padding(.trailing, 16),
                    alignment: .topTrailing
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var actionTile: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT ACTION")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color.HYPE.primary)
                
                Text(viewModel.currentAction.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                
                Text(viewModel.currentPhase == .expanding ? "High Confidence (88%)" : "Medium Confidence")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: {
                // Execute action / play book
            }) {
                Text("Execute")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.base)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.HYPE.tangerine) // Strict constraint: Tangerine ONLY for primary executions
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.HYPE.primary.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.HYPE.primary.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECENT POSTS")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
                .kerning(1)
            
            VStack(spacing: 12) {
                ForEach([viewModel.mockVideo1, viewModel.mockVideo2, viewModel.mockVideo3]) { video in
                    NavigationLink(destination: PostDetailView(video: video)) {
                        HStack(spacing: 16) {
                            // Thumbnail placeholder
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 60, height: 80)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(video.title)
                                    .font(.system(size: 14, weight: .bold))
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
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

}

struct AccountTrendSparklineView: View {
    let mockData = [20, 25, 22, 45, 60, 55, 92]
    
    // Determine trend from last data point vs previous
    var trendDirection: TrendDirection {
        guard mockData.count >= 2 else { return .flat }
        let last = mockData.last!
        let prev = mockData[mockData.count - 2]
        if last > prev { return .up }
        if last < prev { return .down }
        return .flat
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let maxVal = mockData.max() ?? 100
                let width = geometry.size.width
                let height = geometry.size.height
                let step = width / CGFloat(mockData.count - 1)
                
                for (index, value) in mockData.enumerated() {
                    let point = CGPoint(
                        x: CGFloat(index) * step,
                        y: height - (CGFloat(value) / CGFloat(maxVal) * height)
                    )
                    
                    if index == 0 {
                        path.move(to: point)
                    } else {
                        // Create a smooth curve
                        let prevPoint = CGPoint(
                            x: CGFloat(index - 1) * step,
                            y: height - (CGFloat(mockData[index - 1]) / CGFloat(maxVal) * height)
                        )
                        path.addCurve(
                            to: point,
                            control1: CGPoint(x: prevPoint.x + step/2, y: prevPoint.y),
                            control2: CGPoint(x: point.x - step/2, y: point.y)
                        )
                    }
                }
            }
            .stroke(GraphColorResolver.strokeColor(trend: trendDirection), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            .shadow(color: GraphColorResolver.strokeColor(trend: trendDirection).opacity(0.5), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Subcomponents

struct BlinkingMomentumIndicator: View {
    let momentumIndex: Int
    @State private var isBlinking = false
    
    var color: Color {
        if momentumIndex >= 80 {
            return Color.HYPE.tea // Green
        } else if momentumIndex >= 50 {
            return Color.orange // Moderate / Orange
        } else {
            return Color.HYPE.error // Red / Slow dying
        }
    }
    
    var text: String {
        if momentumIndex >= 80 {
            return "Momentum: Strong & Stable. Maintain cadence."
        } else if momentumIndex >= 50 {
            return "Momentum: Moderate. Monitor closely."
        } else {
            return "Momentum: Slow dying. Action required."
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .opacity(isBlinking ? 1.0 : 0.4)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isBlinking)
                .onAppear {
                    isBlinking = true
                }
            
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            Spacer()
        }
    }
}

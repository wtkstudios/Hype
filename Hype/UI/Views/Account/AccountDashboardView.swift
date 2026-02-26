import SwiftUI

struct AccountDashboardView: View {
    let userId: String
    
    @State private var selectedRange: TimeRange = .thirtyDays
    @Environment(\.dismiss) private var dismiss
    
    enum TimeRange: String, CaseIterable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"
    }
    
    var body: some View {
        ZStack {
            Color.HYPE.base.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    timeRangeSelector
                    sparklinesSection
                    deltaCardsSection
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 64)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("ACCOUNT")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.8))
                    .kerning(2)
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Placeholder Premium Gradient Image
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.HYPE.primary.opacity(0.8), Color.HYPE.tea.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(Circle().stroke(Color.HYPE.tea.opacity(0.3), lineWidth: 1))
            
            VStack(spacing: 4) {
                Text("@creator")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                
                Text("128.4K Followers • 4.2M Likes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
                
                Text("Comments (tracked): 312.5K")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.HYPE.primary.opacity(0.8))
            }
            
            // Large OVERALL Score
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("OVERALL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                    .kerning(1)
                
                Text("92")
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(Color.HYPE.text)
            }
            .padding(.top, 4)
            
            Text("High Stability")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.HYPE.tea)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation {
                        selectedRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(selectedRange == range ? Color.HYPE.base : Color.HYPE.text.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedRange == range ? Color.HYPE.text : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 24)
    }
    
    private var sparklinesSection: some View {
        VStack(spacing: 24) {
            ChartRow(title: "Followers Trend (Local)", trend: .up, isCritical: false)
            ChartRow(title: "Avg Likes/Post (Tracked)", trend: .flat, isCritical: false)
            ChartRow(title: "Avg Comments/Post", trend: .down, isCritical: false)
            ChartRow(title: "Overall Score", trend: .down, isCritical: true)
        }
    }
    
    private var deltaCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LOCAL SNAPSHOT DELTAS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color.HYPE.text.opacity(0.5))
                .kerning(1)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DeltaCard(title: "Followers", value: "+1.2K", subtitle: "(\(selectedRange.rawValue))")
                DeltaCard(title: "Avg Likes/Post", value: "+5.4%", subtitle: "Tracked")
                DeltaCard(title: "Avg Comments/Post", value: "-2.1%", subtitle: "Tracked")
                DeltaCard(title: "Posting Cadence", value: "4.2", subtitle: "posts/week")
            }
        }
    }
}

// MARK: - Mini Components

struct ChartRow: View {
    let title: String
    let trend: TrendDirection
    let isCritical: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.8))
            
            // Stand-in sparkline. In production this would accept the local array
            // of AccountDailySnapshot properties relevant to the timeframe.
            AccountTrendSparklineView()
                .frame(height: 36)
                .overlay(
                    // Draw custom colored overlay to force dynamic testing
                    AccountTrendSparklineView()
                        .colorMultiply(GraphColorResolver.strokeColor(trend: trend, isCritical: isCritical))
                )
        }
    }
}

struct DeltaCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.6))
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(value.contains("-") ? Color.HYPE.error : Color.HYPE.text)
            
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.HYPE.primary.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

import SwiftUI
import Combine

// MARK: - Enable swipe-back when navigation back button is hidden

/// Re-enables the interactive pop (swipe-right) gesture when the default back button is hidden.
struct InteractivePopGestureModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(InteractivePopGestureView())
    }
}

private struct InteractivePopGestureView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let nav = uiViewController.navigationController {
                nav.interactivePopGestureRecognizer?.isEnabled = true
                nav.interactivePopGestureRecognizer?.delegate = context.coordinator
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

extension View {
    func enableSwipeBack() -> some View {
        modifier(InteractivePopGestureModifier())
    }
}

struct AccountDashboardView: View {
    let userId: String
    var profileImageURL: String = ""
    var handle: String = "@creator"
    
    @State private var selectedTimeframe: DashboardTimeframe = .thirtyDays
    @State private var selectedMetric: GrowthMetricType = .followers
    @Environment(\.dismiss) private var dismiss
    
    // Mock data
    private let metrics = AccountMetrics.mock
    private let projection = GrowthProjection.mock
    private let milestones = MilestoneProjection.mock
    private let healthScore = HypeHealthScore.mock
    
    private let stabilityLabel: StabilityLabel = .moderate
    private let volatilityStd: Double = 14.5
    
    var body: some View {
        ZStack {
            Color.HYPE.base.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // 0. Orbital Identity — Profile + Hype Health
                    VStack(spacing: 8) {
                        ProfileHypeRingView(score: healthScore.score, profileImageURL: profileImageURL)
                        
                        Text(handle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.HYPE.text.opacity(0.7))
                    }
                    
                    // 1. Hero Metric Strip
                    HeroMetricStripView(metrics: metrics)
                    
                    // 2. Timeframe Toggle
                    timeframeToggle
                    
                    // 3. Growth Trajectory Panel
                    trajectoryPanel
                    
                    // 4. Volatility Index
                    VolatilityBarView(stabilityLabel: stabilityLabel, volatilityStd: volatilityStd)
                    
                    // 5. Predictive Growth Engine
                    predictiveSection
                    
                    // 6. Milestone Projections
                    milestoneSection
                    

                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("DASHBOARD")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.8))
                    .kerning(2)
            }
        }
    }
    
    // MARK: - 2. Timeframe Toggle
    
    private var timeframeToggle: some View {
        HStack(spacing: 0) {
            ForEach(DashboardTimeframe.allCases, id: \.self) { tf in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTimeframe = tf
                    }
                }) {
                    Text(tf.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(selectedTimeframe == tf ? Color.HYPE.base : Color.HYPE.text.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTimeframe == tf ? Color.HYPE.text : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - 3. Growth Trajectory Panel
    
    private var trajectoryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Metric selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GrowthMetricType.allCases, id: \.self) { metric in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMetric = metric
                            }
                        }) {
                            Text(metric.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(selectedMetric == metric ? Color.HYPE.base : Color.HYPE.text.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedMetric == metric ? Color.HYPE.tea : Color.white.opacity(0.05))
                                )
                        }
                    }
                }
            }
            
            // Graph
            GrowthTrajectoryView(
                dataPoints: GrowthDataGenerator.generate(for: selectedTimeframe, metric: selectedMetric),
                metricLabel: "\(selectedMetric.rawValue) — \(selectedTimeframe.rawValue)"
            )
            .id("\(selectedTimeframe.rawValue)-\(selectedMetric.rawValue)") // Force re-draw on change
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - 5. Predictive Growth Engine
    
    private var predictiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PREDICTIVE ENGINE")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .kerning(0.8)
            
            // A. Projected 30-Day Growth
            VStack(alignment: .leading, spacing: 10) {
                Text("If current momentum continues…")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                    .italic()
                
                HStack(spacing: 16) {
                    projectionKPI(label: "FOLLOWERS", value: "+\(NumberFormatterUtils.formatCompact(number: projection.projectedFollowers))")
                    projectionKPI(label: "VIEWS", value: "+\(NumberFormatterUtils.formatCompact(number: projection.projectedViews))")
                    projectionKPI(label: "ENGAGE", value: "+\(String(format: "%.1f", projection.projectedEngagement))%")
                }
            }
            
            Divider().opacity(0.06)
            
            // B. Required Posting Cadence
            VStack(alignment: .leading, spacing: 6) {
                Text("To maintain current growth rate…")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                    .italic()
                
                HStack(spacing: 4) {
                    Text("Recommended:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                    Text("\(Int(projection.cadenceRecommended)) posts/week")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.HYPE.tea)
                }
                
                HStack(spacing: 4) {
                    Text("Your cadence:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                    Text(String(format: "%.1f posts/week", projection.cadenceActual))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(projection.cadenceActual >= projection.cadenceRecommended ? Color.HYPE.tea : Color(hex: "E6A23C"))
                }
            }
            
            // C. Momentum Decay Warning
            if let decayDays = projection.momentumDecayDays {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "E6A23C").opacity(0.8))
                    Text("Momentum decay risk in \(decayDays) days.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "E6A23C").opacity(0.8))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "E6A23C").opacity(0.06))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func projectionKPI(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color.HYPE.tea)
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(Color.HYPE.text.opacity(0.35))
                .kerning(0.3)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 6. Milestone Projections
    
    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEXT MILESTONES")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
                .kerning(0.8)
            
            VStack(spacing: 8) {
                ForEach(milestones) { milestone in
                    HStack(spacing: 12) {
                        Image(systemName: milestone.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.HYPE.tea.opacity(0.6))
                            .frame(width: 24)
                        
                        Text(milestone.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.HYPE.text.opacity(0.7))
                        
                        Spacer()
                        
                        Text("~\(milestone.daysRemaining) days")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text)
                    }
                    .padding(.vertical, 8)
                    .overlay(Divider().opacity(0.05), alignment: .bottom)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

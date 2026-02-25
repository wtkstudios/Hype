import SwiftUI

struct AlertInboxView: View {
    // MVP Mock data for alerts
    let mockAlerts = [
        AlertEvent(id: "1", accountId: "1", videoId: "1", type: .momentumSpike, createdAt: Date().addingTimeInterval(-600), deliveredAt: nil, messageTitle: "Momentum Spike: Waitlist Launch Hook", messageBody: "Your video is over-indexing by 150%. Respond to top comments now.", severity: "warn", triggerMetric: "+150% VS BASELINE", actionLine: "Respond with Video Reply", isRead: false),
        AlertEvent(id: "2", accountId: "1", videoId: "2", type: .secondaryWindow, createdAt: Date().addingTimeInterval(-86400), deliveredAt: nil, messageTitle: "Secondary Push Detected", messageBody: "An older video is accelerating again. Post a follow-up or pin a new comment.", severity: "info", triggerMetric: "ALGORITHM EXTENDED", actionLine: "Post follow-up within 30m", isRead: true),
        AlertEvent(id: "3", accountId: "1", videoId: "3", type: .underperform, createdAt: Date().addingTimeInterval(-172800), deliveredAt: nil, messageTitle: "Underperforming Hook", messageBody: "Views are 70% below baseline. Consider private/repost with alternate hook.", severity: "critical", triggerMetric: "-70% VS BASELINE", actionLine: "Prepare Alternate Hook", isRead: true)
    ]
    
    @State private var activeFilter: String = "All"
    let filters = ["All", "Critical", "Watch", "Info"]
    
    var filteredAlerts: [AlertEvent] {
        if activeFilter == "All" {
            return mockAlerts
        }
        return mockAlerts.filter { $0.severity.lowercased() == activeFilter.lowercased() }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.HYPE.base.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        filterChips
                        alertsList
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("ALERTS")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
            
            Spacer()
            
            Text("3 NEW")
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.HYPE.error.opacity(0.2))
                .foregroundColor(Color.HYPE.error)
                .cornerRadius(4)
        }
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            activeFilter = filter
                        }
                    }) {
                        Text(filter.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(activeFilter == filter ? Color.HYPE.primary : Color.white.opacity(0.1))
                            .foregroundColor(activeFilter == filter ? Color.HYPE.base : Color.HYPE.text)
                            .cornerRadius(100)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var alertsList: some View {
        VStack(spacing: 16) {
            ForEach(filteredAlerts, id: \.id) { alert in
                // Mapped Action: In real app this wraps a NavigationLink passing the video context
                alertCard(for: alert)
            }
        }
    }
    
    private func alertCard(for alert: AlertEvent) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Unread indicator + Icon
            VStack {
                Circle()
                    .fill(alert.isRead ? Color.clear : Color.HYPE.error)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    iconForSeverity(alert.severity)
                    
                    Text(alert.messageTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                    
                    Spacer()
                    
                    Text(timeString(from: alert.createdAt))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                }
                
                Text(alert.triggerMetric)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(Color.HYPE.primary)
                    .cornerRadius(4)
                
                Text(alert.messageBody)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(alert.actionLine.uppercased())
                        .font(.system(size: 12, weight: .black))
                }
                .foregroundColor(Color.HYPE.text)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    alert.severity == "warn" ? Color.HYPE.primary.opacity(0.5) : 
                    alert.severity == "critical" ? Color.HYPE.error.opacity(0.5) : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private func iconForSeverity(_ severity: String) -> some View {
        if severity == "critical" {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.HYPE.error)
                .font(.system(size: 14))
        } else if severity == "warn" {
            Image(systemName: "flame.fill")
                .foregroundColor(Color.HYPE.primary) // Strict constraint: removed energy usage
                .font(.system(size: 14))
        } else {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color.HYPE.primary)
                .font(.system(size: 14))
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

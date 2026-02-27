import SwiftUI

/// Global Terminal — curated signal layer
struct GlobalTerminalView: View {
    @ObservedObject var dataService: TerminalDataService
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Bloomberg-style Spotlight
                globalSpotlightSection
                
                // Top Movers strip
                topMoversSection
                
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(Color.HYPE.base)
    }
    
    // MARK: - Global Spotlight
    
    private var globalSpotlightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                // Live blinking dot
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text("GLOBAL SPOTLIGHT")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                    .kerning(0.8)
            }
            .padding(.horizontal)
            
            if let spotlight = dataService.globalSpotlight {
                GlobalSpotlightCard(post: spotlight)
                    .padding(.horizontal)
            } else {
                EmptyStateCard(title: "No breakouts detected", subtitle: "Check back when the network heats up.", actionText: nil)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Top Movers
    
    private var topMoversSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOP MOVERS")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                        .kerning(0.8)
                    Text("Breakout & strong expanding")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.3))
                }
                Spacer()
            }
            .padding(.horizontal)
            
            let movers = dataService.globalTopMovers
            if movers.isEmpty {
                EmptyStateCard(title: "No top movers", subtitle: "Only breakout and expanding (>75%) posts appear here.", actionText: nil)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(movers) { post in
                            GlobalMoverCard(post: post)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Global Spotlight Card (Bloomberg-alert style)

struct GlobalSpotlightCard: View {
    let post: TerminalPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Alert label
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.red)
                Text("BREAKOUT NOW")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color.red)
                    .kerning(0.5)
            }
            
            // Creator + Post info
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.HYPE.primary.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(post.creatorHandle.prefix(2)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.HYPE.primary)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(post.creatorHandle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.HYPE.text)
                    Text(post.title ?? "Post")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("HYPE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                    Text(String(format: "%.0f", post.hypeScore))
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(Color.HYPE.text)
                }
            }
            
            // Stats row — compact
            HStack(spacing: 0) {
                compactStat(label: "ACCEL", value: post.acceleration.map { "+\(Int($0))" } ?? "–")
                Spacer()
                compactStat(label: "VPM", value: post.vpm.map { "\(Int($0))" } ?? "–")
                Spacer()
                compactStat(label: "PHASE", value: post.phase.rawValue.uppercased())
                    .foregroundColor(post.phase.color)
            }
            
            // View CTA
            Button(action: {
                if let url = URL(string: "tiktok://") { UIApplication.shared.open(url) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("VIEW")
                        .font(.system(size: 12, weight: .black))
                        .kerning(0.5)
                }
                .foregroundColor(Color.HYPE.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        // Subtle red ambient glow
        .shadow(color: Color.red.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    private func compactStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(Color.HYPE.text.opacity(0.4))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
        }
    }
}

// MARK: - Global Top Mover Card (compact horizontal scroll)

struct GlobalMoverCard: View {
    let post: TerminalPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Phase badge
            Text(post.phase.rawValue.uppercased())
                .font(.system(size: 9, weight: .black))
                .foregroundColor(post.phase.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(post.phase.color.opacity(0.12))
                .cornerRadius(4)
            
            Text(post.creatorHandle)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.HYPE.text)
                .lineLimit(1)
            
            // 3-stat mini block
            VStack(alignment: .leading, spacing: 4) {
                miniRow(label: "ACCEL", value: post.acceleration.map { "+\(Int($0))" } ?? "–")
                miniRow(label: "HYPE", value: String(format: "%.0f", post.hypeScore))
            }
        }
        .padding(12)
        .frame(width: 130)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(post.phase.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func miniRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(Color.HYPE.text.opacity(0.35))
                .kerning(0.3)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
        }
    }
}

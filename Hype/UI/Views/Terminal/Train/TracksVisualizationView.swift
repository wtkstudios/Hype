import SwiftUI

struct TracksVisualizationView: View {
    let activePosts: [TerminalPost]
    let stations: [DistributionPhase] = [.testing, .expanding, .breakout, .plateau, .reignite]
    
    @Namespace private var tracksNS
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPulsing = false
    
    // Find phase with highest acceleration post to be the "active" phase
    private var activePhase: DistributionPhase? {
        activePosts.max(by: { ($0.acceleration ?? 0) < ($1.acceleration ?? 0) })?.phase
    }
    
    private var activePhaseIsPositive: Bool {
        let maxPost = activePosts.max(by: { ($0.acceleration ?? 0) < ($1.acceleration ?? 0) })
        return (maxPost?.acceleration ?? 0) >= 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("TRACKS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.6))
                Spacer()
                Text("ACTIVE: \(activePosts.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.HYPE.text.opacity(0.4))
            }
            .padding(.horizontal)
            
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(stations.enumerated()), id: \.element) { index, station in
                    let trains = activePosts.filter { $0.phase == station }
                    
                    VStack(alignment: .center, spacing: 12) {
                        // Header
                        VStack(spacing: 4) {
                            Text(stationLabel(for: station))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(station.color)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(height: 24)
                            
                            Text("\(trains.count)")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundColor(Color.HYPE.base)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(station.color)
                                .clipShape(Capsule())
                        }
                        
                        Rectangle()
                            .fill(Color.HYPE.text.opacity(0.1))
                            .frame(width: 2, height: 16)
                        
                        // Trains
                        VStack(spacing: 8) {
                            let visibleTrains = trains.prefix(4)
                            ForEach(visibleTrains, id: \.id) { train in
                                let isAcc = (train.acceleration ?? 0) > 0
                                TrainCapsuleView(phase: station, isAccelerating: isAcc)
                                    .transition(.opacity.animation(.linear(duration: 0.15)))
                                    .matchedGeometryEffectIf(id: "train-\(train.id)", in: tracksNS, enabled: !reduceMotion)
                            }
                            
                            if trains.count > 4 {
                                Text("+\(trains.count - 4)")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.HYPE.text.opacity(0.4))
                            }
                            
                            if trains.isEmpty {
                                TrainCapsuleView(phase: station, isAccelerating: false)
                                    .opacity(0.0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if activePhase == station && !reduceMotion {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(activePhaseIsPositive ? Color.HYPE.neonGreen : Color.HYPE.neonRed)
                                    .opacity(isPulsing ? 0.12 : 0.06)
                            }
                        }
                    )
                    
                    if index < stations.count - 1 {
                        Divider()
                            .background(Color.HYPE.text.opacity(0.08))
                    }
                }
            }
            .animation(!reduceMotion ? .easeInOut(duration: 0.28) : .linear(duration: 0.15), value: activePosts.map { "\($0.id)-\($0.phase.rawValue)" })
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 16)
        .background(Color.HYPE.base)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.HYPE.text.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(16)
        .padding(.horizontal)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onDisappear {
            isPulsing = false
        }
    }
    
    private func stationLabel(for phase: DistributionPhase) -> String {
        if phase == .reignite { return "RE-\nIGNITE" }
        return phase.rawValue.uppercased()
    }
}

// Helper for conditional matchedGeometryEffect
extension View {
    @ViewBuilder
    func matchedGeometryEffectIf(id: String, in namespace: Namespace.ID, enabled: Bool) -> some View {
        if enabled {
            self.matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}

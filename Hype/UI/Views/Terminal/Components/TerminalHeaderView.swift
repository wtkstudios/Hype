import SwiftUI

enum TerminalMode: String, CaseIterable {
    case train = "Train"
    case terminal = "Terminal"
    case circles = "Circles"
}

struct TerminalHeaderView: View {
    @Binding var selectedMode: TerminalMode
    @Binding var selectedScope: TerminalScope
    let circles: [HypeCircle]
    
    private var scopeName: String {
        switch selectedScope {
        case .all: return "All Circles"
        case .circle(let id): return circles.first(where: { $0.id == id })?.name ?? "Unknown"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Top row: Title + Circle Selector
            HStack {
                Text("TERMINAL")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
                
                Spacer()
                
                // Circle selector Menu
                Menu {
                    Button("All Circles") {
                        selectedScope = .all
                    }
                    if !circles.isEmpty {
                        Divider()
                        ForEach(circles) { circle in
                            Button(circle.name) {
                                selectedScope = .circle(circle.id)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(scopeName)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.HYPE.text)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.HYPE.text.opacity(0.6))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.HYPE.base)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.HYPE.text.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            
            // Segmented Control
            HStack(spacing: 0) {
                ForEach(TerminalMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation {
                            selectedMode = mode
                        }
                    }) {
                        Text(mode.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedMode == mode ? Color.HYPE.base : Color.HYPE.text.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedMode == mode ? Color.HYPE.text : Color.clear)
                            )
                    }
                }
            }
            .padding(4)
            .background(Color.HYPE.base)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.HYPE.text.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.HYPE.base)
    }
}

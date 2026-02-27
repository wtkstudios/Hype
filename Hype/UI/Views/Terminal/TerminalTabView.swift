import SwiftUI

/// New Terminal root view: My Circle (default) vs Global terminal
struct TerminalTabView: View {
    @StateObject private var dataService = TerminalDataService.shared
    @State private var selectedTab: TerminalMainTab = .myCircle
    @State private var showingRequests = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top navigation bar
            terminalNavBar
            
            // Content
            ZStack {
                if dataService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.HYPE.text))
                } else {
                    switch selectedTab {
                    case .myCircle:
                        MyCircleView(dataService: dataService)
                            .transition(.opacity)
                    case .global:
                        GlobalTerminalView(dataService: dataService)
                            .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.HYPE.base)
        }
        .sheet(isPresented: $showingRequests) {
            CircleRequestsView(dataService: dataService)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    private var terminalNavBar: some View {
        ZStack {
            // Centered tab toggle
            Picker("", selection: $selectedTab) {
                Text("My Circle").tag(TerminalMainTab.myCircle)
                Text("Global").tag(TerminalMainTab.global)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            
            // Right-side icons
            HStack {
                Spacer()
                HStack(spacing: 12) {
                    // Requests inbox
                    Button(action: { showingRequests = true }) {
                        ZStack(alignment: .topLeading) {
                            Image(systemName: "person.2")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.HYPE.text.opacity(0.8))
                            
                            let pending = dataService.circleRequests.filter { $0.isPending && $0.isInbound }.count
                            if pending > 0 {
                                Text("\(pending)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: -2, y: -4)
                            }
                        }
                    }
                    
                    // Add person
                    Button(action: {}) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.HYPE.text.opacity(0.8))
                    }
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color.HYPE.base)
        .overlay(Divider().opacity(0.1), alignment: .bottom)
    }
}

enum TerminalMainTab {
    case myCircle
    case global
}

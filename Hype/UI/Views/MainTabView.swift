import SwiftUI
import Network

struct MainTabView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    init() {
        UITabBar.appearance().backgroundColor = UIColor(Color.HYPE.base)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.HYPE.text.opacity(0.4))
    }
    
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem {
                    Image(systemName: "circle.grid.2x2.fill")
                    Text("Dashboard")
                }
            
            IntelligenceDashboardView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Intelligence")
                }
            
            AlertInboxView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Alerts")
                }
                .badge(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(Color.HYPE.text)
        .overlay(
            VStack {
                if !networkMonitor.isConnected {
                    offlineBanner
                }
                Spacer()
            }
        )
    }
    
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("OFFLINE MODE - USING CACHED DATA")
                .font(.system(size: 10, weight: .black, design: .monospaced))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.HYPE.error)
        .foregroundColor(Color.HYPE.base)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
}

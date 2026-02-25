import SwiftUI

struct SettingsView: View {
    @ObservedObject var subManager = SubscriptionManager.shared
    
    // MVP Mock Accounts
    let connectedAccounts = [
        "@creator",
        "@agency_client_1"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.HYPE.base.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                        accountsSection
                        subscriptionSection
                        dangerZone
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("SETTINGS")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(Color.HYPE.text)
            
            Spacer()
        }
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONNECTED ACCOUNTS")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            VStack(spacing: 8) {
                ForEach(connectedAccounts, id: \.self) { account in
                    HStack {
                        Circle()
                            .fill(account == "@creator" ? Color.HYPE.primary : Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Text(account)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.HYPE.text)
                        
                        Spacer()
                        
                        if account == "@creator" {
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(Color.HYPE.text)
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                
                if subManager.isAgency {
                    Button(action: {
                        // Trigger TikTok Login Kit Add Account
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Connect Another Account")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.HYPE.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                } else {
                    gateBanner(title: "Multi-Account", subtitle: "Requires HYPE Agency Tier")
                }
            }
        }
    }
    
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SUBSCRIPTION")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.HYPE.text.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(subManager.isAgency ? "HYPE AGENCY" : (subManager.isPro ? "HYPE PRO" : "FREE PLAN"))
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(Color.HYPE.text)
                    
                    Spacer()
                    
                    if subManager.isAgency || subManager.isPro {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.HYPE.energy)
                            .foregroundColor(Color.HYPE.base)
                            .cornerRadius(4)
                    }
                }
                
                if !subManager.isAgency {
                    Text("Unlock Agency to manage unlimited clients, export PDF reports, and see predictive posting windows.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        Task { try? await subManager.purchasePro() }
                    }) {
                        Text("Upgrade to Agency")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.HYPE.base)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.HYPE.text)
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        let baseline = BaselineProfile(id: "1", accountId: "@creator", computedAt: Date(), windowDays: 30)
                        if let url = ReportGenerator.shared.generatePDFReport(for: "@creator", score: 92.0, baseline: baseline) {
                            print("PDF Generated at: \(url)")
                            // Normally presenting UIActivityViewController here
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Agency Report (PDF)")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.HYPE.primary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var dangerZone: some View {
         VStack(alignment: .leading, spacing: 16) {
             
             // ALERTS TUNING BUTTON
             Text("PREFERENCES")
                 .font(.system(size: 14, weight: .bold))
                 .foregroundColor(Color.HYPE.text.opacity(0.7))
             
             NavigationLink(destination: AlertThresholdsView()) {
                 HStack {
                     Image(systemName: "slider.horizontal.3")
                     Text("Advanced Alert Thresholds")
                     Spacer()
                     Image(systemName: "chevron.right")
                         .font(.system(size: 12))
                 }
                 .font(.system(size: 14, weight: .bold))
                 .foregroundColor(Color.HYPE.text)
                 .padding()
                 .frame(maxWidth: .infinity, alignment: .leading)
                 .background(Color.white.opacity(0.05))
                 .cornerRadius(12)
             }
             .padding(.bottom, 16)
             
             Text("DATA & PRIVACY")
                 .font(.system(size: 14, weight: .bold))
                 .foregroundColor(Color.HYPE.error)
             
             Button(action: {
                 // Trigger hard disconnect
                 try? KeychainManager.shared.clearAll()
                 // Drop DB Tables
             }) {
                 Text("Delete My Data & Disconnect TikTok")
                     .font(.system(size: 14, weight: .bold))
                     .foregroundColor(Color.HYPE.error)
                     .padding()
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .background(Color.HYPE.error.opacity(0.1))
                     .cornerRadius(12)
             }
         }
     }
    
    private func gateBanner(title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(Color.HYPE.text.opacity(0.4))
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.HYPE.energy.opacity(0.6))
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
    }
}

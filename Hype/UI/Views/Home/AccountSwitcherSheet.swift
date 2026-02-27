import SwiftUI

struct AccountSwitcherSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.HYPE.base.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 24) {
                // Connected Accounts Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("CONNECTED ACCOUNTS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        // Active Account
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(red: 0.5, green: 0.53, blue: 0.9)) // Purple
                                .frame(width: 32, height: 32)
                            
                            Text("@creator")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.HYPE.text)
                            
                            Spacer()
                            
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(Color.HYPE.text)
                                .cornerRadius(4)
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        
                        // Inactive Account
                        Button(action: {
                            // Switch account action
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Text("@agency_client_1")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.HYPE.text)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Locked Multi-Account
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.HYPE.text.opacity(0.5))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Multi-Account")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.HYPE.text.opacity(0.5))
                                
                                Text("Requires HYPE Agency Tier")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3)) // Orange
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Subscription Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("SUBSCRIPTION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("FREE PLAN")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(Color.white)
                        
                        Text("Unlock Agency to manage unlimited clients, export PDF reports, and see predictive posting windows.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.HYPE.text.opacity(0.7))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: {
                            // Upgrade action
                            dismiss()
                        }) {
                            Text("Upgrade to Agency")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.92, green: 0.9, blue: 0.87)) // Beige
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 24)
        }
    }
}

import SwiftUI

/// Circle Requests — Accept / Decline inbound, Search & Send outbound
struct CircleRequestsView: View {
    @ObservedObject var dataService: TerminalDataService
    @State private var searchText = ""
    @State private var sentRequests: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    
    private var pendingInbound: [CircleRequest] {
        dataService.circleRequests.filter { $0.isInbound && $0.isPending }
    }
    
    var body: some View {
        ZStack {
            Color.HYPE.base.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CIRCLE REQUESTS")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(Color.HYPE.text)
                        Text("Manage your creator network")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.HYPE.text.opacity(0.4))
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.HYPE.text.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Divider().opacity(0.08)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Search & Send
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ADD TO CIRCLE")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color.HYPE.text.opacity(0.4))
                                .kerning(0.8)
                                .padding(.horizontal)
                            
                            HStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.HYPE.text.opacity(0.4))
                                    TextField("Search by @handle", text: $searchText)
                                        .foregroundColor(Color.HYPE.text)
                                        .font(.system(size: 14))
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                                
                                Button(action: {
                                    guard !searchText.isEmpty else { return }
                                    let handle = searchText.hasPrefix("@") ? searchText : "@\(searchText)"
                                    dataService.sendCircleRequest(to: handle)
                                    sentRequests.insert(handle)
                                    searchText = ""
                                }) {
                                    Text("Send")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.HYPE.base)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.HYPE.primary)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                            
                            if !sentRequests.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("PENDING SENT")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundColor(Color.HYPE.text.opacity(0.3))
                                        .padding(.horizontal)
                                    
                                    ForEach(Array(sentRequests), id: \.self) { handle in
                                        HStack {
                                            Text(handle)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(Color.HYPE.text.opacity(0.6))
                                            Spacer()
                                            Text("PENDING")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(Color.HYPE.primary.opacity(0.6))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.HYPE.primary.opacity(0.08))
                                                .cornerRadius(4)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        
                        Divider().opacity(0.08)
                        
                        // Inbound requests
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INCOMING")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color.HYPE.text.opacity(0.4))
                                .kerning(0.8)
                                .padding(.horizontal)
                            
                            if pendingInbound.isEmpty {
                                Text("No pending requests.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.HYPE.text.opacity(0.3))
                                    .padding(.horizontal)
                            } else {
                                ForEach(pendingInbound) { req in
                                    RequestRow(req: req, dataService: dataService)
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct RequestRow: View {
    let req: CircleRequest
    @ObservedObject var dataService: TerminalDataService
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.HYPE.primary.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(req.fromHandle.dropFirst().prefix(2)).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.HYPE.primary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(req.fromHandle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.text)
                Text("Wants to join your Circle")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.HYPE.text.opacity(0.4))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // Decline
                Button(action: { dataService.declineRequest(req) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.HYPE.text.opacity(0.5))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                }
                
                // Accept
                Button(action: { dataService.acceptCircleRequest(req) }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.HYPE.tea)
                        .frame(width: 30, height: 30)
                        .background(Color.HYPE.tea.opacity(0.12))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

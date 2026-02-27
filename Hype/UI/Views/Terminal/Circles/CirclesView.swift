import SwiftUI

struct CirclesView: View {
    @ObservedObject var dataService: TerminalDataService
    let scope: TerminalScope
    @State private var showingCreateForm = false
    @State private var newCircleName = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Your Circles
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR CIRCLES")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    if dataService.circles.isEmpty {
                        EmptyStateCard(title: "No circles joined", subtitle: "Create or join a momentum pod to compare stats privately.", actionText: nil)
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(dataService.circles) { circle in
                                    // Simulated NavigationLink wrapper since we don't have full NavStack setup here
                                    Button(action: {
                                        // Navigate to CircleDetailView(circle: circle)
                                    }) {
                                        CircleCardView(circle: circle, activeTrainsCount: Int.random(in: 1...5))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Invites (Requested)
                VStack(alignment: .leading, spacing: 12) {
                    Text("PENDING INVITES")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    EmptyStateCard(title: "Inbox Zero", subtitle: "You have no pending circle invitations.", actionText: nil)
                        .padding(.horizontal)
                }
                
                // Recent Signals (Global or Scoped)
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT SIGNALS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.HYPE.text.opacity(0.6))
                        .padding(.horizontal)
                    
                    VStack(spacing: 1) {
                        let signals = dataService.filteredSignals(scope: scope).prefix(4)
                        if signals.isEmpty {
                            EmptyStateCard(title: "No signals yet", subtitle: "Signals appear when momentum shifts occur in your circles.", actionText: nil)
                        } else {
                            ForEach(Array(signals.enumerated()), id: \.element.id) { index, signal in
                                SignalFeedItemView(event: signal, isNew: false)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    showingCreateForm = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create new Circle")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.HYPE.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.HYPE.text)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(Color.HYPE.base)
        .sheet(isPresented: $showingCreateForm) {
            createCircleSheet
        }
    }
    
    // Existing Create Circle logic
    private var createCircleSheet: some View {
        ZStack {
            Color.HYPE.base.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Text("NEW CIRCLE")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(Color.HYPE.text)
                    .padding(.top, 24)
                
                TextField("Circle Name", text: $newCircleName)
                    .padding()
                    .background(Color.HYPE.text.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(Color.HYPE.text)
                    .padding(.horizontal)
                
                Button("Create") {
                    if !newCircleName.isEmpty {
                        dataService.createCircle(name: newCircleName)
                        newCircleName = ""
                        showingCreateForm = false
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.HYPE.base)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.HYPE.text)
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

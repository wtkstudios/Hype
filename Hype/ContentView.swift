//
//  ContentView.swift
//  Hype
//
//  Created by wtk.chiko on 25/02/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = TikTokAuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}

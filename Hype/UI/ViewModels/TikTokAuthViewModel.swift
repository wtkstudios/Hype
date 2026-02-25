import Foundation
import SwiftUI
import Combine

#if canImport(TikTokOpenSDK)
import TikTokOpenSDK
#endif

class TikTokAuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?
    
    private let mockUserId = "creator"
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let _ = try? KeychainManager.shared.retrieve(for: mockUserId) {
            isAuthenticated = true
        }
    }
    
    func login() {
        isAuthenticating = true
        errorMessage = nil
        
        #if canImport(TikTokOpenSDK)
        let request = TikTokOpenSDKAuthRequest()
        request.permissions = ["user.info.basic", "video.list"]
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                self.isAuthenticating = false
                self.errorMessage = "Failed to find root view controller."
                return
            }
            
            request.send(rootVC) { [weak self] response in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    
                    guard let authResponse = response as? TikTokOpenSDKAuthResponse else {
                        self?.errorMessage = "Invalid response from TikTok"
                        return
                    }
                    
                    if authResponse.errCode == .success, let code = authResponse.code {
                        self?.storeTokenAndSync(token: code)
                    } else {
                        self?.errorMessage = "Auth failed: \(authResponse.errString ?? "Unknown Error")"
                    }
                }
            }
        }
        #else
        // Mock Implementation Fallback (until SDK is installed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.storeTokenAndSync(token: "mock_api_token_xyz")
        }
        #endif
    }
    
    private func storeTokenAndSync(token: String) {
        do {
            try KeychainManager.shared.save(token: token, for: mockUserId)
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.isAuthenticating = false
            }
            Task {
                await syncInitialData()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to store token"
            }
        }
    }
    
    func logout() {
        do {
            try KeychainManager.shared.delete(for: mockUserId)
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to clear token"
            }
        }
    }
    
    private func syncInitialData() async {
        do {
            if FeatureFlags.useMockData {
                return
            }
            // Real sync disabled until APIClient supports sending tokens
            // let _ = try await SyncManager.shared.performFullSync(for: mockUserId)
        } catch {
            print("Sync failed: \(error)")
        }
    }
}

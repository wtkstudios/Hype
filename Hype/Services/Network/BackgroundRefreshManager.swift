import Foundation
import BackgroundTasks
import UIKit

class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let refreshTaskID = "com.hype.app.refreshMetrics"
    
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundRefreshManager.refreshTaskID, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundRefreshManager.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 mins minimum retry
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled background refresh")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next one immediately
        scheduleAppRefresh()
        
        // Provide an expiration handler
        task.expirationHandler = {
            // Cancel current ongoing networking operations if possible
        }
        
        Task {
            do {
                // In production, we iterate through active connected accounts in DB.
                // For MVP, we pass a hardcoded/mocked string
                let mockUserId = "mock_user_123"
                if try KeychainManager.shared.retrieve(for: mockUserId) != nil {
                     try await SyncManager.shared.performFullSync(for: mockUserId)
                     // Trigger engine on newly downloaded data
                     // Note: You would normally iterate the fetched videos here.
                }
                task.setTaskCompleted(success: true)
            } catch {
                print("Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
}

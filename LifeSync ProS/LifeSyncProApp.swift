import SwiftUI

@main
struct LifeSyncProApp: App {
    // Using UserDataManager consistently throughout the app
    @StateObject private var userDataManager = UserDataManager()
    
    var body: some Scene {
        WindowGroup {
            if userDataManager.hasCompletedOnboarding {
                ContentView(userDataManager: userDataManager)
                    .environmentObject(userDataManager)
        
            } else {
                OnboardingView()
                    .environmentObject(userDataManager)
            }
        }
    }
}

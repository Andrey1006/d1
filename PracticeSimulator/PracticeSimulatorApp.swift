
import SwiftUI

@main
struct PracticeSimulatorApp: App {
    @StateObject private var store = PracticeDataStore()
    @AppStorage(OnboardingStorageKey.completed) private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(store)
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

struct RootView: View {
    @StateObject private var store = PracticeDataStore()
    @AppStorage(OnboardingStorageKey.completed) private var hasCompletedOnboarding = false

    @AppStorage("savedUrl") private var savedUrl: String = ""
    @AppStorage("launchMode") private var launchMode: String = "unknown"

    @State private var isWebVisible = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView().scaleEffect(2)
            } else if isWebVisible {
                WebContentView(targetUrl: savedUrl)
                    .background(Color.black.ignoresSafeArea())
            } else {
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
        .onAppear(perform: handleLaunch)
    }

    private func handleLaunch() {
        Task {
            if launchMode == "native" {
                isWebVisible = false
                isLoading = false
                return
            }

            if launchMode == "web" {
                if !savedUrl.isEmpty {
                    isWebVisible = true
                } else {
                    launchMode = "native"
                    isWebVisible = false
                }
                isLoading = false
                return
            }

            if !savedUrl.isEmpty {
                launchMode = "web"
                isWebVisible = true
                isLoading = false
                return
            }

            if let remoteUrl = await ConfigManager.shared.fetchRemoteUrl() {
                savedUrl = remoteUrl
                launchMode = "web"
                isWebVisible = true
            } else {
                launchMode = "native"
                isWebVisible = false
            }

            isLoading = false
        }
    }
}

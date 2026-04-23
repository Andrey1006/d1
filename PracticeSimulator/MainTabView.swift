
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SessionRootView()
                .tabItem {
                    Label("Session", systemImage: "timer")
                }

            JournalRootView()
                .tabItem {
                    Label("Journal", systemImage: "list.bullet.rectangle")
                }

            AnalyticsRootView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }

            InsightsRootView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb.max")
                }

            SettingsRootView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(PSTheme.accent)
    }
}

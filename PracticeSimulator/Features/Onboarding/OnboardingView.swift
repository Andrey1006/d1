
import SwiftUI

enum OnboardingStorageKey {
    static let completed = "ps.hasCompletedOnboarding"
}

struct OnboardingView: View {
    @AppStorage(OnboardingStorageKey.completed) private var hasCompletedOnboarding = false
    @State private var page = 0

    var body: some View {
        ZStack {
            PSBackground()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        finish()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PSTheme.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                Text(PSTheme.appDisplayName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(PSTheme.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TabView(selection: $page) {
                    OnboardingPageView(
                        symbol: "chart.bar.doc.horizontal",
                        title: "Measure your practice",
                        text: "Each session captures practice type, duration, a mode coefficient (0.7×, 1×, 1.5×, 2×), and subjective metrics: difficulty, concentration, fatigue, and result quality. That keeps data comparable over time."
                    )
                    .tag(0)

                    OnboardingPageView(
                        symbol: "chart.xyaxis.line",
                        title: "Analytics & baseline",
                        text: "1× is your baseline for comparisons. Use the journal and reports with time ranges, compare modes A/B, and spot patterns: where quality is higher and what fatigue “costs” you."
                    )
                    .tag(1)

                    OnboardingPageView(
                        symbol: "timer",
                        title: "Start with one session",
                        text: "Open the Session tab, pick a type and coefficient, run the timer—or log duration directly. More honest 1× sessions make analytics more reliable."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .psHiddenScrollIndicators()

                HStack(spacing: 16) {
                    if page > 0 {
                        Button("Back") {
                            withAnimation { page -= 1 }
                        }
                        .buttonStyle(PSSecondaryButtonStyle())
                    }

                    Spacer(minLength: 0)

                    Button(page < 2 ? "Next" : "Get started") {
                        if page < 2 {
                            withAnimation { page += 1 }
                        } else {
                            finish()
                        }
                    }
                    .buttonStyle(PSPrimaryButtonStyle())
                    .frame(maxWidth: page == 0 ? .infinity : nil)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.bottom, 8)
            }
        }
        .tint(PSTheme.accent)
    }

    private func finish() {
        hasCompletedOnboarding = true
    }
}

private struct OnboardingPageView: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: symbol)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(PSTheme.accent)
                    .padding(.top, 24)

                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(PSTheme.textPrimary)
                    .multilineTextAlignment(.center)

                PSCard {
                    Text(text)
                        .font(.body)
                        .foregroundStyle(PSTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .psHiddenScrollIndicators()
    }
}

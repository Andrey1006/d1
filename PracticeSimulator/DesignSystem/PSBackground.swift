
import SwiftUI

struct PSBackground: View {
    var body: some View {
        LinearGradient(
            colors: [PSTheme.gradientTop, PSTheme.gradientBottom, PSTheme.backgroundDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct PSChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            PSBackground()
            content
        }
    }
}

extension View {
    func psScreenBackground() -> some View {
        modifier(PSChromeModifier())
    }

    func psHiddenScrollIndicators() -> some View {
        scrollIndicators(.hidden)
    }
}

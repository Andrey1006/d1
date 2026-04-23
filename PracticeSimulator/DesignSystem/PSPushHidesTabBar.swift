
import SwiftUI

extension View {
    func psPushHidesTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }
}

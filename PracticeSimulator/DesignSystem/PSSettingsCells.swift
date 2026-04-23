
import SwiftUI

struct PSSettingsSectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(PSTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }
}

struct PSSettingsCellGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PSTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PSTheme.cardStroke, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PSSettingsRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(PSTheme.cardStroke.opacity(0.9))
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

struct PSSettingsRow<Leading: View, Trailing: View>: View {
    private let leading: Leading
    private let trailing: Trailing
    private let minHeight: CGFloat

    init(
        minHeight: CGFloat = 48,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.minHeight = minHeight
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            leading
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
    }
}

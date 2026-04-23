
import SwiftUI

struct CoefficientChipRow: View {
    @EnvironmentObject private var store: PracticeDataStore
    @Binding var selectedValue: Double

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.sortedCoefficientChoices(), id: \.self) { value in
                    let selected = abs(value - selectedValue) < 0.001
                    Button {
                        selectedValue = value
                    } label: {
                        Text(store.coefficientLabel(value))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selected ? PSTheme.accent.opacity(0.35) : PSTheme.cardFill)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(selected ? PSTheme.accent : PSTheme.cardStroke, lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(selected ? PSTheme.textPrimary : PSTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .psHiddenScrollIndicators()
    }
}

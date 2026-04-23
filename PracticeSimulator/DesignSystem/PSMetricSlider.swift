
import SwiftUI

struct PSMetricSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double> = 1...10

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PSTheme.textPrimary)
                Spacer()
                Text("\(Int(value))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(PSTheme.accent)
            }
            Slider(value: $value, in: range, step: 1)
                .tint(PSTheme.accent)
        }
    }
}

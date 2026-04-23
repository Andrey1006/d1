
import SwiftUI

struct PSTextField: View {
    var title: String? = nil
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disableAutocorrection: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(PSTheme.textSecondary)
            }

            ZStack(alignment: axis == .vertical ? .topLeading : .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(axis == .vertical ? .body : .body)
                        .foregroundStyle(PSTheme.textSecondary.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, axis == .vertical ? 12 : 11)
                        .allowsHitTesting(false)
                }

                Group {
                    if axis == .vertical {
                        TextField("", text: $text, axis: .vertical)
                            .lineLimit(lineLimit ?? 3...8)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .focused($isFocused)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(disableAutocorrection)
                .keyboardType(keyboardType)
                .foregroundStyle(PSTheme.textPrimary)
                .tint(PSTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, axis == .vertical ? 12 : 11)
            }
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(PSTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(isFocused ? PSTheme.accent.opacity(0.9) : PSTheme.cardStroke, lineWidth: isFocused ? 1.5 : 1)
                    )
            )
            .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}

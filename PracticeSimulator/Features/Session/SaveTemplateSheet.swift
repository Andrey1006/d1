
import SwiftUI

struct SaveTemplateSheet: View {
    @Binding var titleText: String
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("The current type and coefficient are saved for a quick start next time.")
                    .font(.footnote)
                    .foregroundStyle(PSTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                PSTextField(
                    title: "Title",
                    placeholder: "e.g. Technique · 1×",
                    text: $titleText,
                    disableAutocorrection: true
                )

                Button(action: onSave) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PSPrimaryButtonStyle())
                .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .psScreenBackground()
            .navigationTitle("Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(PSTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

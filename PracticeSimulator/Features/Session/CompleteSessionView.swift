
import SwiftUI

struct CompleteSessionView: View {
    @EnvironmentObject private var store: PracticeDataStore
    @Environment(\.dismiss) private var dismiss

    let practiceTypeId: UUID
    let coefficient: Double
    let startedAt: Date

    @State private var durationMinutes: Int
    @State private var durationExtraSeconds: Int
    @State private var difficulty: Double = 5
    @State private var concentration: Double = 5
    @State private var fatigue: Double = 5
    @State private var quality: Double = 5
    @State private var note: String = ""
    @State private var excludeFromAnalytics = false

    init(practiceTypeId: UUID, coefficient: Double, startedAt: Date, initialDurationSeconds: Int) {
        self.practiceTypeId = practiceTypeId
        self.coefficient = coefficient
        self.startedAt = startedAt
        let total = max(1, initialDurationSeconds)
        _durationMinutes = State(initialValue: total / 60)
        _durationExtraSeconds = State(initialValue: total % 60)
    }

    private var durationSeconds: Int {
        max(1, durationMinutes * 60 + durationExtraSeconds)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            Stepper("Minutes: \(durationMinutes)", value: $durationMinutes, in: 0...600)
                                .foregroundStyle(PSTheme.textPrimary)
                            Stepper("Seconds: \(durationExtraSeconds)", value: $durationExtraSeconds, in: 0...59)
                                .foregroundStyle(PSTheme.textPrimary)
                            Text("Total: \(TimeFormatting.clock(seconds: durationSeconds))")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(PSTheme.accent)
                        }
                    }

                    PSCard {
                        VStack(spacing: 18) {
                            PSMetricSlider(title: "Difficulty", value: $difficulty)
                            PSMetricSlider(title: "Concentration", value: $concentration)
                            PSMetricSlider(title: "Fatigue", value: $fatigue)
                            PSMetricSlider(title: "Outcome quality", value: $quality)
                        }
                    }

                    PSCard {
                        PSTextField(
                            title: "Note",
                            placeholder: "Optional",
                            text: $note,
                            axis: .vertical,
                            lineLimit: 3...6
                        )
                    }

                    PSCard {
                        Toggle("Exclude from analytics", isOn: $excludeFromAnalytics)
                            .tint(PSTheme.accent)
                            .foregroundStyle(PSTheme.textPrimary)
                        Text("Use for off days, illness, or unusual conditions.")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)
                    }

                    Button(action: save) {
                        Text("Save session")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PSPrimaryButtonStyle())
                }
                .padding(20)
            }
            .psHiddenScrollIndicators()
            .psScreenBackground()
            .navigationTitle("Log session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(PSTheme.textSecondary)
                }
            }
        }
    }

    private func save() {
        let session = PracticeSession(
            startedAt: startedAt,
            endedAt: Date(),
            practiceTypeId: practiceTypeId,
            coefficient: coefficient,
            durationSeconds: durationSeconds,
            difficulty: Int(difficulty),
            concentration: Int(concentration),
            fatigue: Int(fatigue),
            quality: Int(quality),
            note: note,
            excludeFromAnalytics: excludeFromAnalytics
        )
        store.addSession(session)
        dismiss()
    }
}

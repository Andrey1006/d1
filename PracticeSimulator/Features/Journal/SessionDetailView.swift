
import SwiftUI

struct SessionDetailView: View {
    @EnvironmentObject private var store: PracticeDataStore
    @Environment(\.dismiss) private var dismiss

    let session: PracticeSession

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PSCard {
                    VStack(alignment: .leading, spacing: 10) {
                        row("Type", store.practiceTypeName(for: session.practiceTypeId))
                        row("Mode", store.coefficientLabel(session.coefficient))
                        row("Started", TimeFormatting.shortRelative(session.startedAt))
                        row("Ended", TimeFormatting.shortRelative(session.endedAt))
                        row("Duration", TimeFormatting.clock(seconds: session.durationSeconds))
                    }
                }

                PSCard {
                    VStack(alignment: .leading, spacing: 10) {
                        row("Difficulty", "\(session.difficulty)/10")
                        row("Concentration", "\(session.concentration)/10")
                        row("Fatigue", "\(session.fatigue)/10")
                        row("Quality", "\(session.quality)/10")
                    }
                }

                if !session.note.isEmpty {
                    PSCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            Text(session.note)
                                .foregroundStyle(PSTheme.textPrimary)
                        }
                    }
                }

                PSCard {
                    HStack {
                        Text("Excluded from analytics")
                            .foregroundStyle(PSTheme.textPrimary)
                        Spacer()
                        Text(session.excludeFromAnalytics ? "Yes" : "No")
                            .foregroundStyle(PSTheme.textSecondary)
                    }
                }
            }
            .padding(20)
        }
        .psHiddenScrollIndicators()
        .psScreenBackground()
        .psPushHidesTabBar()
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") { showEdit = true }
                    Button("Delete", role: .destructive) { showDeleteConfirm = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(PSTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditSessionView(session: session)
                .environmentObject(store)
        }
        .confirmationDialog("Delete this session?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteSession(id: session.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(PSTheme.textSecondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(PSTheme.textPrimary)
        }
        .font(.subheadline)
    }
}

struct EditSessionView: View {
    @EnvironmentObject private var store: PracticeDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: PracticeSession

    init(session: PracticeSession) {
        _draft = State(initialValue: session)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Practice type")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            Picker("Type", selection: $draft.practiceTypeId) {
                                ForEach(store.practiceTypes) { type in
                                    Text(type.name).tag(type.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .tint(PSTheme.accent)
                        }
                    }

                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Coefficient")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            CoefficientChipRow(selectedValue: Binding(
                                get: { draft.coefficient },
                                set: { draft.coefficient = AnalyticsService.roundCoefficient($0) }
                            ))
                            Text(store.coefficientDetail(for: draft.coefficient))
                                .font(.footnote)
                                .foregroundStyle(PSTheme.textSecondary)
                        }
                    }

                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            Stepper("Minutes: \(draft.durationSeconds / 60)", value: Binding(
                                get: { draft.durationSeconds / 60 },
                                set: { newM in
                                    let sec = draft.durationSeconds % 60
                                    draft.durationSeconds = max(1, newM * 60 + sec)
                                }
                            ), in: 0...600)
                            .foregroundStyle(PSTheme.textPrimary)
                            Stepper("Seconds: \(draft.durationSeconds % 60)", value: Binding(
                                get: { draft.durationSeconds % 60 },
                                set: { newS in
                                    let min = draft.durationSeconds / 60
                                    draft.durationSeconds = max(1, min * 60 + newS)
                                }
                            ), in: 0...59)
                            .foregroundStyle(PSTheme.textPrimary)
                        }
                    }

                    PSCard {
                        VStack(spacing: 18) {
                            PSMetricSlider(title: "Difficulty", value: Binding(
                                get: { Double(draft.difficulty) },
                                set: { draft.difficulty = Int($0) }
                            ))
                            PSMetricSlider(title: "Concentration", value: Binding(
                                get: { Double(draft.concentration) },
                                set: { draft.concentration = Int($0) }
                            ))
                            PSMetricSlider(title: "Fatigue", value: Binding(
                                get: { Double(draft.fatigue) },
                                set: { draft.fatigue = Int($0) }
                            ))
                            PSMetricSlider(title: "Outcome quality", value: Binding(
                                get: { Double(draft.quality) },
                                set: { draft.quality = Int($0) }
                            ))
                        }
                    }

                    PSCard {
                        PSTextField(
                            title: "Note",
                            placeholder: "Optional",
                            text: $draft.note,
                            axis: .vertical,
                            lineLimit: 3...6
                        )
                    }

                    PSCard {
                        Toggle("Exclude from analytics", isOn: $draft.excludeFromAnalytics)
                            .tint(PSTheme.accent)
                            .foregroundStyle(PSTheme.textPrimary)
                    }

                    Button("Save changes") {
                        store.updateSession(draft)
                        dismiss()
                    }
                    .buttonStyle(PSPrimaryButtonStyle())
                }
                .padding(20)
            }
            .psHiddenScrollIndicators()
            .psScreenBackground()
            .navigationTitle("Edit session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(PSTheme.textSecondary)
                }
            }
        }
    }
}

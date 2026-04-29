
import Combine
import SwiftUI

struct SessionView: View {
    @EnvironmentObject private var store: PracticeDataStore

    @State private var selectedTypeId: UUID?
    @State private var selectedCoefficientValue: Double = 1.0

    @State private var isRunning = false
    @State private var segmentStart: Date?
    @State private var pausedAccumulated: TimeInterval = 0
    @State private var tick = 0

    @State private var showComplete = false
    @State private var sessionStartedAt: Date?

    @State private var showSaveTemplateSheet = false
    @State private var newTemplateTitle = ""

    private var elapsedSeconds: Int {
        let segment: TimeInterval
        if isRunning, let start = segmentStart {
            segment = Date().timeIntervalSince(start)
        } else {
            segment = 0
        }
        return Int(pausedAccumulated + segment)
    }

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PSCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily goal")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)

                        HStack(alignment: .firstTextBaseline) {
                            Text("\(store.todayPracticeSeconds / 60) min")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(PSTheme.textPrimary)
                            Text("of \(store.dailyGoalMinutes) min")
                                .font(.subheadline)
                                .foregroundStyle(PSTheme.textSecondary)
                            Spacer()
                            Text("Streak \(store.currentStreakDays)d")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(store.todayGoalMet ? PSTheme.accent : PSTheme.textSecondary)
                        }

                        ProgressView(value: store.todayProgress)
                            .tint(PSTheme.accent)

                        if store.bestStreakDays > 0 {
                            Text("Best streak: \(store.bestStreakDays)d")
                                .font(.caption2)
                                .foregroundStyle(PSTheme.textSecondary)
                        }
                    }
                }

                if !store.recentSessionCombos().isEmpty {
                    PSCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent combinations")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(store.recentSessionCombos().enumerated()), id: \.offset) { _, combo in
                                        Button {
                                            selectedTypeId = combo.practiceTypeId
                                            selectedCoefficientValue = combo.coefficient
                                        } label: {
                                            Text("\(store.practiceTypeName(for: combo.practiceTypeId)) · \(store.coefficientLabel(combo.coefficient))")
                                                .font(.caption.weight(.semibold))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule(style: .continuous)
                                                        .fill(PSTheme.cardFill)
                                                        .overlay(Capsule().stroke(PSTheme.cardStroke, lineWidth: 1))
                                                )
                                                .foregroundStyle(PSTheme.textPrimary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .psHiddenScrollIndicators()
                        }
                    }
                }

                if !store.sessionTemplates.isEmpty {
                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Templates")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            ForEach(store.sessionTemplates) { template in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(PSTheme.textPrimary)
                                        Text("\(store.practiceTypeName(for: template.practiceTypeId)) · \(store.coefficientLabel(template.coefficient))")
                                            .font(.caption2)
                                            .foregroundStyle(PSTheme.textSecondary)
                                    }
                                    Spacer()
                                    Button("Apply") {
                                        selectedTypeId = template.practiceTypeId
                                        selectedCoefficientValue = template.coefficient
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PSTheme.accent)
                                }
                                .padding(.vertical, 6)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        store.deleteSessionTemplate(id: template.id)
                                    }
                                }
                            }
                        }
                    }
                }

                PSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Practice type")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)
                        Picker("Type", selection: Binding(
                            get: { selectedTypeId ?? store.practiceTypes.first?.id },
                            set: { selectedTypeId = $0 }
                        )) {
                            ForEach(store.practiceTypes) { type in
                                Text(type.name).tag(Optional(type.id))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .tint(PSTheme.accent)
                    }
                }

                PSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mode coefficient")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)
                        CoefficientChipRow(selectedValue: $selectedCoefficientValue)
                        Text(store.coefficientDetail(for: selectedCoefficientValue))
                            .font(.footnote)
                            .foregroundStyle(PSTheme.textSecondary)
                    }
                }

                PSCard {
                    VStack(spacing: 16) {
                        Text(TimeFormatting.clock(seconds: elapsedSeconds))
                            .font(.system(size: 44, weight: .light, design: .monospaced))
                            .foregroundStyle(PSTheme.textPrimary)
                            .padding(.vertical, 4)
                            .id(tick)

                        HStack(spacing: 12) {
                            Button(action: start) {
                                Label("Start", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PSPrimaryButtonStyle())
                            .disabled(isRunning || activeTypeId == nil)

                            Button(action: pause) {
                                Label("Pause", systemImage: "pause.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PSSecondaryButtonStyle())
                            .disabled(!isRunning)
                        }

                        Button(role: .destructive, action: prepareComplete) {
                            Label("Finish and log", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PSSecondaryButtonStyle())
                        .disabled(activeTypeId == nil)

                        Button {
                            newTemplateTitle = suggestedTemplateTitle()
                            showSaveTemplateSheet = true
                        } label: {
                            Label("Save as template", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PSSecondaryButtonStyle())
                        .disabled(activeTypeId == nil)
                    }
                }

                Text("You can stop the timer and adjust duration on the log screen if needed.")
                    .font(.caption)
                    .foregroundStyle(PSTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .psHiddenScrollIndicators()
        .psScreenBackground()
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if selectedTypeId == nil {
                selectedTypeId = store.practiceTypes.first?.id
            }
            ensureValidCoefficientSelection()
        }
        .onReceive(timer) { _ in
            if isRunning {
                tick += 1
            }
        }
        .sheet(isPresented: $showComplete, onDismiss: resetTimerState) {
            Group {
                if let typeId = activeTypeId {
                    CompleteSessionView(
                        practiceTypeId: typeId,
                        coefficient: selectedCoefficientValue,
                        startedAt: sessionStartedAt ?? Date(),
                        initialDurationSeconds: max(1, elapsedSeconds)
                    )
                    .environmentObject(store)
                }
            }
        }
        .sheet(isPresented: $showSaveTemplateSheet) {
            SaveTemplateSheet(
                titleText: $newTemplateTitle,
                onSave: {
                    guard let tid = activeTypeId else { return }
                    store.addSessionTemplate(
                        title: newTemplateTitle,
                        practiceTypeId: tid,
                        coefficient: selectedCoefficientValue,
                        targetDurationSeconds: elapsedSeconds > 0 ? elapsedSeconds : nil
                    )
                    showSaveTemplateSheet = false
                },
                onCancel: { showSaveTemplateSheet = false }
            )
        }
    }

    private var activeTypeId: UUID? {
        selectedTypeId ?? store.practiceTypes.first?.id
    }

    private func suggestedTemplateTitle() -> String {
        guard let tid = activeTypeId else { return "Template" }
        let typeName = store.practiceTypeName(for: tid)
        return "\(typeName) · \(store.coefficientLabel(selectedCoefficientValue))"
    }

    private func ensureValidCoefficientSelection() {
        let choices = store.sortedCoefficientChoices()
        guard !choices.isEmpty else { return }
        if !choices.contains(where: { abs($0 - selectedCoefficientValue) < 0.001 }) {
            selectedCoefficientValue = choices.first(where: { abs($0 - 1.0) < 0.001 }) ?? choices[0]
        }
    }

    private func start() {
        guard activeTypeId != nil else { return }
        if sessionStartedAt == nil {
            sessionStartedAt = Date()
        }
        guard !isRunning else { return }
        segmentStart = Date()
        isRunning = true
    }

    private func pause() {
        guard isRunning, let start = segmentStart else { return }
        pausedAccumulated += Date().timeIntervalSince(start)
        segmentStart = nil
        isRunning = false
    }

    private func prepareComplete() {
        if isRunning, let start = segmentStart {
            pausedAccumulated += Date().timeIntervalSince(start)
            segmentStart = nil
            isRunning = false
        }
        showComplete = true
    }

    private func resetTimerState() {
        isRunning = false
        segmentStart = nil
        pausedAccumulated = 0
        tick = 0
        sessionStartedAt = nil
    }
}

struct PSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(PSTheme.accent.opacity(configuration.isPressed ? 0.75 : 1))
            )
            .foregroundStyle(PSTheme.textPrimary)
    }
}

struct PSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(PSTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PSTheme.cardStroke, lineWidth: 1)
                    )
            )
            .foregroundStyle(PSTheme.textPrimary.opacity(configuration.isPressed ? 0.7 : 1))
    }
}

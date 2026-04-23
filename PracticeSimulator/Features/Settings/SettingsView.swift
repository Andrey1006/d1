
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PracticeDataStore

    @State private var newTypeName = ""
    @State private var showResetConfirm = false
    @State private var editingType: PracticeType?
    @State private var newCoefficientText = ""
    @State private var showExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                PSSettingsSectionTitle(text: "Practice types")
                PSSettingsCellGroup {
                    ForEach(Array(store.practiceTypes.enumerated()), id: \.element.id) { index, type in
                        PSSettingsRow(minHeight: 52) {
                            Text(type.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(PSTheme.textPrimary)
                        } trailing: {
                            HStack(spacing: 16) {
                                Button {
                                    editingType = type
                                } label: {
                                    Text("Edit")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PSTheme.accent)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    deleteType(id: type.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.red.opacity(0.85))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if index < store.practiceTypes.count - 1 {
                            PSSettingsRowDivider()
                        }
                    }

                    if !store.practiceTypes.isEmpty {
                        PSSettingsRowDivider()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        PSTextField(title: nil, placeholder: "New practice type", text: $newTypeName)
                        Button {
                            store.addPracticeType(name: newTypeName)
                            newTypeName = ""
                        } label: {
                            Text("Add type")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PSPrimaryButtonStyle())
                        .disabled(newTypeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(16)
                }

                PSSettingsSectionTitle(text: "Coefficients")
                PSSettingsCellGroup {
                    VStack(alignment: .leading, spacing: 14) {
                        PSTextField(
                            title: nil,
                            placeholder: "New coefficient (e.g. 1.25)",
                            text: $newCoefficientText,
                            keyboardType: .decimalPad,
                            disableAutocorrection: true
                        )
                        Button {
                            if let v = parsedNewCoefficient() {
                                store.addCustomCoefficient(v)
                                newCoefficientText = ""
                            }
                        } label: {
                            Text("Add coefficient")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PSPrimaryButtonStyle())
                        .disabled(parsedNewCoefficient() == nil)

                        if store.customCoefficients.isEmpty {
                            Text("Presets 0.7×–2× stay available; add extra values for the chip row.")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                        }
                    }
                    .padding(16)

                    if !store.customCoefficients.isEmpty {
                        PSSettingsRowDivider()
                        ForEach(Array(store.customCoefficients.enumerated()), id: \.element) { index, c in
                            PSSettingsRow {
                                Text(store.coefficientLabel(c))
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(PSTheme.textPrimary)
                            } trailing: {
                                Button("Remove") {
                                    store.removeCustomCoefficient(c)
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.red.opacity(0.85))
                            }
                            if index < store.customCoefficients.count - 1 {
                                PSSettingsRowDivider()
                            }
                        }
                    }
                }

                PSSettingsSectionTitle(text: "Data")
                PSSettingsCellGroup {
                    statRow("Sessions in journal", value: "\(store.sessions.count)", showDivider: true)
                    statRow("In analytics (total)", value: "\(store.analyticsSessions.count)", showDivider: true)
                    statRow("Reporting period", value: store.reportingPeriod.title, showDivider: false)
                }

                PSSettingsSectionTitle(text: "Export")
                PSSettingsCellGroup {
                    Button(action: exportAll) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(PSTheme.accent)
                            Text("Export all sessions (CSV)")
                                .font(.body.weight(.medium))
                                .foregroundStyle(PSTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PSTheme.textSecondary.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                PSSettingsSectionTitle(text: "Danger zone")
                PSSettingsCellGroup {
                    Button {
                        showResetConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.orange.opacity(0.9))
                            Text("Reset all data")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.red.opacity(0.95))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, 24)
        }
        .psHiddenScrollIndicators()
        .psScreenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $editingType) { type in
            PracticeTypeEditorView(type: type)
                .environmentObject(store)
        }
        .sheet(isPresented: $showExportSheet, onDismiss: { exportURL = nil }) {
            if let url = exportURL {
                ActivityShareView(items: [url])
            }
        }
        .confirmationDialog(
            "Delete all sessions and restore default practice types?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                store.resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func statRow(_ title: String, value: String, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            PSSettingsRow {
                Text(title)
                    .foregroundStyle(PSTheme.textSecondary)
            } trailing: {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PSTheme.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            if showDivider {
                PSSettingsRowDivider()
            }
        }
    }

    private func parsedNewCoefficient() -> Double? {
        let normalized = newCoefficientText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func exportAll() {
        do {
            exportURL = try CSVExporter.writeTempCSVFile(sessions: store.sessions) { store.practiceTypeName(for: $0) }
            showExportSheet = true
        } catch {}
    }

    private func deleteType(id: UUID) {
        store.deletePracticeType(id: id)
    }
}

struct PracticeTypeEditorView: View {
    @EnvironmentObject private var store: PracticeDataStore
    @Environment(\.dismiss) private var dismiss

    let type: PracticeType
    @State private var name: String

    init(type: PracticeType) {
        self.type = type
        _name = State(initialValue: type.name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PSSettingsSectionTitle(text: "Name")
                    PSSettingsCellGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            PSTextField(title: nil, placeholder: "Type name", text: $name)
                        }
                        .padding(16)
                    }
                }
                .padding(20)
                .padding(.bottom, 32)
            }
            .psHiddenScrollIndicators()
            .psScreenBackground()
            .navigationTitle("Practice type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(PSTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updatePracticeType(id: type.id, name: name)
                        dismiss()
                    }
                    .foregroundStyle(PSTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

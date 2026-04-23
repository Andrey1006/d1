
import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: PracticeDataStore

    @State private var coefficientFilter: CoefficientFilter = .all
    @State private var showExportSheet = false
    @State private var exportURL: URL?

    private var periodSessions: [PracticeSession] {
        store.sessions(in: store.reportingPeriod, analyticsOnly: false)
    }

    private var filtered: [PracticeSession] {
        let list = periodSessions
        switch coefficientFilter {
        case .all:
            return list
        case .value(let v):
            return list.filter { abs($0.coefficient - v) < 0.001 }
        }
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(PSTheme.textSecondary)
                    Text("No sessions match the selected filters")
                        .foregroundStyle(PSTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                journalRow(session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .psHiddenScrollIndicators()
            }
        }
        .psScreenBackground()
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Period", selection: Binding(
                        get: { store.reportingPeriod },
                        set: { store.setReportingPeriod($0) }
                    )) {
                        ForEach(ReportingPeriod.allCases) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    Picker("Mode", selection: $coefficientFilter) {
                        ForEach(store.journalCoefficientFilters(), id: \.self) { f in
                            Text(f.title).tag(f)
                        }
                    }
                    Divider()
                    Button {
                        exportFilteredCSV()
                    } label: {
                        Label("Export CSV (filtered)", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(PSTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showExportSheet, onDismiss: { exportURL = nil }) {
            if let url = exportURL {
                ActivityShareView(items: [url])
            }
        }
    }

    private func exportFilteredCSV() {
        do {
            exportURL = try CSVExporter.writeTempCSVFile(sessions: filtered) { store.practiceTypeName(for: $0) }
            showExportSheet = true
        } catch {}
    }

    private func journalRow(_ session: PracticeSession) -> some View {
        PSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(store.practiceTypeName(for: session.practiceTypeId))
                        .font(.headline)
                        .foregroundStyle(PSTheme.textPrimary)
                    Spacer()
                    Text(store.coefficientLabel(session.coefficient))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PSTheme.accent)
                }
                Text(TimeFormatting.shortRelative(session.endedAt))
                    .font(.caption)
                    .foregroundStyle(PSTheme.textSecondary)
                HStack(spacing: 12) {
                    metricChip("Q", session.quality)
                    metricChip("Co", session.concentration)
                    metricChip("F", session.fatigue)
                    Spacer()
                    Text(TimeFormatting.clock(seconds: session.durationSeconds))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PSTheme.textSecondary)
                }
            }
        }
    }

    private func metricChip(_ title: String, _ value: Int) -> some View {
        Text("\(title) \(value)")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(PSTheme.cardFill))
            .overlay(Capsule().stroke(PSTheme.cardStroke, lineWidth: 1))
            .foregroundStyle(PSTheme.textSecondary)
    }
}

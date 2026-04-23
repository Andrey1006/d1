
import Charts
import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: PracticeDataStore
    @State private var showGlossary = false

    private var sessions: [PracticeSession] {
        store.analyticsSessionsInReportingPeriod
    }

    private var baseline: AnalyticsService.BaselineSnapshot? {
        AnalyticsService.baseline(from: sessions)
    }

    private var aggregates: [AnalyticsService.ModeAggregate] {
        AnalyticsService.aggregatesByCoefficient(sessions: sessions, labelForCoefficient: store.coefficientLabel)
    }

    private var trend: [WeeklyTrendPoint] {
        WeeklyTrendPoint.build(from: sessions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PSCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Period: \(store.reportingPeriod.title)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PSTheme.accent)
                        Text("Baseline (1×)")
                            .font(.headline)
                            .foregroundStyle(PSTheme.textPrimary)
                        Text("1× sessions in period: \(store.baselineSessionCount). Aim for ≥ 5 for stable comparisons.")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)
                        if let b = baseline {
                            HStack {
                                baselineColumn("Quality", String(format: "%.1f", b.avgQuality))
                                baselineColumn("Conc.", String(format: "%.1f", b.avgConcentration))
                                baselineColumn("Fatigue", String(format: "%.1f", b.avgFatigue))
                                baselineColumn("Min", String(format: "%.0f", b.avgDurationMinutes))
                            }
                            .padding(.top, 4)
                        } else {
                            Text("No 1× sessions in analytics for the selected period.")
                                .font(.footnote)
                                .foregroundStyle(PSTheme.textSecondary)
                        }
                    }
                }

                if aggregates.count >= 2 {
                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Average quality by mode")
                                .font(.headline)
                                .foregroundStyle(PSTheme.textPrimary)
                            Chart(aggregates) { row in
                                BarMark(
                                    x: .value("Mode", row.label),
                                    y: .value("Quality", row.avgQuality)
                                )
                                .foregroundStyle(PSTheme.accent)
                            }
                            .chartYScale(domain: 0...10)
                            .frame(height: 220)
                            Text("n — session count per mode.")
                                .font(.caption2)
                                .foregroundStyle(PSTheme.textSecondary)
                        }
                    }

                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Efficiency index")
                                .font(.headline)
                                .foregroundStyle(PSTheme.textPrimary)
                            Text("Combines quality, concentration, and fatigue cost; higher is better.")
                                .font(.caption)
                                .foregroundStyle(PSTheme.textSecondary)
                            Chart(aggregates) { row in
                                BarMark(
                                    x: .value("Mode", row.label),
                                    y: .value("Efficiency", row.efficiencyIndex)
                                )
                                .foregroundStyle(Color.white.opacity(0.85))
                            }
                            .frame(height: 200)
                        }
                    }
                }

                if trend.count >= 2 {
                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quality trend by week")
                                .font(.headline)
                                .foregroundStyle(PSTheme.textPrimary)
                            Chart(trend) { p in
                                LineMark(
                                    x: .value("Week", p.weekStart),
                                    y: .value("Quality", p.avgQuality)
                                )
                                .foregroundStyle(PSTheme.accent)
                                PointMark(
                                    x: .value("Week", p.weekStart),
                                    y: .value("Quality", p.avgQuality)
                                )
                                .foregroundStyle(PSTheme.accent)
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic) { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(PSTheme.cardStroke)
                                    AxisValueLabel()
                                        .foregroundStyle(PSTheme.textSecondary)
                                }
                            }
                            .chartYScale(domain: 0...10)
                            .frame(height: 220)
                        }
                    }
                }

                if sessions.count < 2 {
                    PSCard {
                        Text("Add at least two sessions with different settings in the selected period — charts and comparisons appear automatically.")
                            .font(.footnote)
                            .foregroundStyle(PSTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .psHiddenScrollIndicators()
        .psScreenBackground()
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    ModeComparisonView()
                } label: {
                    Text("A / B")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PSTheme.accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Menu {
                        Picker("Period", selection: Binding(
                            get: { store.reportingPeriod },
                            set: { store.setReportingPeriod($0) }
                        )) {
                            ForEach(ReportingPeriod.allCases) { p in
                                Text(p.title).tag(p)
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(PSTheme.accent)
                    }
                    Button {
                        showGlossary = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(PSTheme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showGlossary) {
            NavigationStack {
                GlossaryView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showGlossary = false }
                        }
                    }
            }
        }
    }

    private func baselineColumn(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(PSTheme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PSTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WeeklyTrendPoint: Identifiable {
    let id: Date
    let weekStart: Date
    let avgQuality: Double

    static func build(from sessions: [PracticeSession]) -> [WeeklyTrendPoint] {
        let cal = Calendar.current
        var buckets: [Date: [Int]] = [:]
        for s in sessions {
            guard let week = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: s.endedAt)) else { continue }
            buckets[week, default: []].append(s.quality)
        }
        return buckets.keys.sorted().map { key in
            let values = buckets[key] ?? []
            let avg = values.isEmpty ? 0 : Double(values.reduce(0, +)) / Double(values.count)
            return WeeklyTrendPoint(id: key, weekStart: key, avgQuality: avg)
        }
    }
}

struct GlossaryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                glossaryBlock(
                    "Quality",
                    "Subjective outcome rating for the session on a 1–10 scale."
                )
                glossaryBlock(
                    "Concentration",
                    "How steadily you could keep attention on the task."
                )
                glossaryBlock(
                    "Fatigue",
                    "Subjective load after the session; helps estimate the cost of a mode."
                )
                glossaryBlock(
                    "Baseline (1×)",
                    "Neutral comparison mode. Other coefficients are interpreted relative to 1× averages."
                )
                glossaryBlock(
                    "Efficiency index",
                    "In-app metric balancing quality and concentration with fatigue and duration."
                )
            }
            .padding(20)
        }
        .psHiddenScrollIndicators()
        .psScreenBackground()
        .navigationTitle("Metrics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func glossaryBlock(_ title: String, _ text: String) -> some View {
        PSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PSTheme.textPrimary)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(PSTheme.textSecondary)
            }
        }
    }
}

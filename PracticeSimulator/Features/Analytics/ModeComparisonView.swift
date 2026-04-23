
import SwiftUI

struct ModeComparisonView: View {
    @EnvironmentObject private var store: PracticeDataStore

    @State private var modeA: Double = 1.0
    @State private var modeB: Double = 1.5

    private var choices: [Double] {
        store.sortedCoefficientChoices()
    }

    private var pool: [PracticeSession] {
        store.analyticsSessionsInReportingPeriod
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mode A")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)
                        CoefficientChipRow(selectedValue: $modeA)
                    }
                }

                PSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mode B")
                            .font(.caption)
                            .foregroundStyle(PSTheme.textSecondary)
                        CoefficientChipRow(selectedValue: $modeB)
                    }
                }

                if let rowA = aggregate(modeA), let rowB = aggregate(modeB) {
                    PSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comparison (period: \(store.reportingPeriod.title))")
                                .font(.headline)
                                .foregroundStyle(PSTheme.textPrimary)
                            comparisonTable(rowA: rowA, rowB: rowB)
                        }
                    }
                } else {
                    PSCard {
                        Text("Not enough sessions for the selected modes in the current period.")
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
        .psPushHidesTabBar()
        .navigationTitle("A / B comparison")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncModesFromChoices()
        }
    }

    private func syncModesFromChoices() {
        guard !choices.isEmpty else { return }
        if !choices.contains(where: { abs($0 - modeA) < 0.001 }) {
            modeA = choices[0]
        }
        if !choices.contains(where: { abs($0 - modeB) < 0.001 }) {
            modeB = choices.count > 1 ? choices[1] : choices[0]
        }
        if abs(modeA - modeB) < 0.001, choices.count > 1 {
            modeB = choices.first { abs($0 - modeA) >= 0.001 } ?? choices[0]
        }
    }

    private func aggregate(_ coeff: Double) -> ModeRow? {
        let rc = AnalyticsService.roundCoefficient(coeff)
        let items = pool.filter { AnalyticsService.roundCoefficient($0.coefficient) == rc }
        guard !items.isEmpty else { return nil }
        let q = averageD(items.map { Double($0.quality) })
        let c = averageD(items.map { Double($0.concentration) })
        let f = averageD(items.map { Double($0.fatigue) })
        let d = averageD(items.map { Double($0.difficulty) })
        let dur = averageD(items.map { Double($0.durationSeconds) / 60.0 })
        return ModeRow(
            label: store.coefficientLabel(coeff),
            count: items.count,
            avgQuality: q,
            avgConcentration: c,
            avgFatigue: f,
            avgDifficulty: d,
            avgDurationMinutes: dur
        )
    }

    private func averageD(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func comparisonTable(rowA: ModeRow, rowB: ModeRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            metricCompareRow("Sessions", a: "\(rowA.count)", b: "\(rowB.count)", pct: nil)
            metricCompareRow("Quality", a: fmt1(rowA.avgQuality), b: fmt1(rowB.avgQuality), pct: pctDiff(rowA.avgQuality, rowB.avgQuality))
            metricCompareRow("Concentration", a: fmt1(rowA.avgConcentration), b: fmt1(rowB.avgConcentration), pct: pctDiff(rowA.avgConcentration, rowB.avgConcentration))
            metricCompareRow("Fatigue", a: fmt1(rowA.avgFatigue), b: fmt1(rowB.avgFatigue), pct: pctDiff(rowA.avgFatigue, rowB.avgFatigue))
            metricCompareRow("Difficulty", a: fmt1(rowA.avgDifficulty), b: fmt1(rowB.avgDifficulty), pct: pctDiff(rowA.avgDifficulty, rowB.avgDifficulty))
            metricCompareRow("Minutes", a: fmt0(rowA.avgDurationMinutes), b: fmt0(rowB.avgDurationMinutes), pct: pctDiff(rowA.avgDurationMinutes, rowB.avgDurationMinutes))
        }
    }

    private func metricCompareRow(_ title: String, a: String, b: String, pct: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(PSTheme.textSecondary)
                .frame(width: 120, alignment: .leading)
            Text("A \(a)")
                .foregroundStyle(PSTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("B \(b)")
                .foregroundStyle(PSTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let pct {
                Text(pct)
                    .font(.caption2)
                    .foregroundStyle(PSTheme.accent)
                    .frame(width: 56, alignment: .trailing)
            } else {
                Spacer().frame(width: 56)
            }
        }
        .font(.caption)
    }

    private func pctDiff(_ x: Double, _ y: Double) -> String {
        guard x > 0.01 else { return "—" }
        let p = (y - x) / x * 100
        let sign = p > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", p))%"
    }

    private func fmt1(_ v: Double) -> String {
        String(format: "%.1f", v)
    }

    private func fmt0(_ v: Double) -> String {
        String(format: "%.0f", v)
    }
}

private struct ModeRow {
    let label: String
    let count: Int
    let avgQuality: Double
    let avgConcentration: Double
    let avgFatigue: Double
    let avgDifficulty: Double
    let avgDurationMinutes: Double
}


import Foundation

enum AnalyticsService {
    struct ModeAggregate: Identifiable {
        var id: Double { coefficient }
        let coefficient: Double
        let label: String
        let count: Int
        let avgQuality: Double
        let avgConcentration: Double
        let avgFatigue: Double
        let avgDifficulty: Double
        let avgDurationMinutes: Double
        let efficiencyIndex: Double
        let stabilityIndex: Double
    }

    struct BaselineSnapshot {
        let count: Int
        let avgQuality: Double
        let avgConcentration: Double
        let avgFatigue: Double
        let avgDurationMinutes: Double
    }

    static func baseline(from sessions: [PracticeSession]) -> BaselineSnapshot? {
        let base = sessions.filter { abs($0.coefficient - 1.0) < 0.001 }
        guard !base.isEmpty else { return nil }
        return BaselineSnapshot(
            count: base.count,
            avgQuality: average(base.map { Double($0.quality) }),
            avgConcentration: average(base.map { Double($0.concentration) }),
            avgFatigue: average(base.map { Double($0.fatigue) }),
            avgDurationMinutes: average(base.map { Double($0.durationSeconds) / 60.0 })
        )
    }

    static func aggregatesByCoefficient(
        sessions: [PracticeSession],
        labelForCoefficient: (Double) -> String
    ) -> [ModeAggregate] {
        let grouped = Dictionary(grouping: sessions) { roundCoefficient($0.coefficient) }
        return grouped.keys.sorted().compactMap { key in
            guard let items = grouped[key], !items.isEmpty else { return nil }
            let qualities = items.map(\.quality).map(Double.init)
            let concentrations = items.map(\.concentration).map(Double.init)
            let fatigues = items.map(\.fatigue).map(Double.init)
            let difficulties = items.map(\.difficulty).map(Double.init)
            let durationsMin = items.map { Double($0.durationSeconds) / 60.0 }

            let avgQ = average(qualities)
            let avgC = average(concentrations)
            let avgF = average(fatigues)
            let avgD = average(difficulties)
            let avgDur = average(durationsMin)

            let efficiency = efficiencyIndex(quality: avgQ, concentration: avgC, fatigue: avgF, durationMinutes: max(avgDur, 0.01))
            let stability = stabilityIndex(values: qualities)

            return ModeAggregate(
                coefficient: key,
                label: labelForCoefficient(key),
                count: items.count,
                avgQuality: avgQ,
                avgConcentration: avgC,
                avgFatigue: avgF,
                avgDifficulty: avgD,
                avgDurationMinutes: avgDur,
                efficiencyIndex: efficiency,
                stabilityIndex: stability
            )
        }
    }

    static func insights(
        sessions: [PracticeSession],
        labelForCoefficient: (Double) -> String
    ) -> [InsightItem] {
        guard sessions.count >= 3 else {
            return [
                InsightItem(
                    kind: .lowData,
                    title: "Gather more data",
                    message: "Meaningful insights need at least 3 sessions. Log your metrics after each practice.",
                    sampleCount: sessions.count
                ),
            ]
        }

        var items: [InsightItem] = []
        let baselineSessions = sessions.filter { abs($0.coefficient - 1.0) < 0.001 }
        let nonBaseline = sessions.filter { abs($0.coefficient - 1.0) >= 0.001 }

        if baselineSessions.count < 3 {
            items.append(
                InsightItem(
                    kind: .baselineCalibration,
                    title: "Calibrate baseline (1×)",
                    message: "Fewer than three sessions at 1×. Add neutral runs so comparisons with 0.7× and 2× are more reliable.",
                    sampleCount: baselineSessions.count,
                    relatedCoefficient: 1.0
                )
            )
        }

        if let best = bestQualityMode(sessions: sessions, label: labelForCoefficient) {
            items.append(best)
        }

        if let fatigue = fatigueQualityPattern(sessions: sessions) {
            items.append(fatigue)
        }

        if !nonBaseline.isEmpty, let cmp = compareToBaseline(sessions: sessions, label: labelForCoefficient) {
            items.append(cmp)
        }

        if items.isEmpty {
            items.append(
                InsightItem(
                    kind: .continuePractice,
                    title: "Keep practicing",
                    message: "No clear pattern between modes yet. Spread sessions across different coefficients.",
                    sampleCount: sessions.count
                )
            )
        }

        return items
    }

    static func roundCoefficient(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func efficiencyIndex(quality: Double, concentration: Double, fatigue: Double, durationMinutes: Double) -> Double {
        let loadPenalty = max(0, fatigue - 5)
        let raw = (quality + concentration) / 2.0 - loadPenalty * 0.35
        let timeNorm = min(durationMinutes / 45.0, 1.4)
        return raw * (0.85 + 0.15 * timeNorm)
    }

    private static func stabilityIndex(values: [Double]) -> Double {
        guard values.count > 1 else { return 1 }
        let mean = average(values)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let std = sqrt(variance)
        return max(0, min(10, 10 - std))
    }

    private static func bestQualityMode(sessions: [PracticeSession], label: (Double) -> String) -> InsightItem? {
        let grouped = Dictionary(grouping: sessions) { roundCoefficient($0.coefficient) }
        var bestKey: Double?
        var bestAvg = -1.0
        for (k, v) in grouped where v.count >= 2 {
            let avg = average(v.map { Double($0.quality) })
            if avg > bestAvg {
                bestAvg = avg
                bestKey = k
            }
        }
        guard let key = bestKey else { return nil }
        let count = grouped[key]?.count ?? 0
        return InsightItem(
            kind: .bestQualityMode,
            title: "Best quality by mode",
            message: "Highest average quality in \(label(key)) across \(count) sessions. See if that matches how it felt.",
            sampleCount: count,
            relatedCoefficient: key
        )
    }

    private static func fatigueQualityPattern(sessions: [PracticeSession]) -> InsightItem? {
        let hi = sessions.filter { $0.fatigue >= 7 }
        let lo = sessions.filter { $0.fatigue <= 4 }
        guard hi.count >= 2, lo.count >= 2 else { return nil }
        let hiQ = average(hi.map { Double($0.quality) })
        let loQ = average(lo.map { Double($0.quality) })
        let diff = loQ - hiQ
        guard abs(diff) >= 0.8 else { return nil }
        let message =
            diff > 0
            ? "With fatigue 7–10, average quality is lower than at 1–4. Consider easing intensity or alternating modes."
            : "Quality holds up at high fatigue — still watch recovery so you do not overload."
        return InsightItem(
            kind: .fatigueQuality,
            title: "Fatigue vs quality",
            message: message,
            sampleCount: sessions.count
        )
    }

    private static func compareToBaseline(sessions: [PracticeSession], label: (Double) -> String) -> InsightItem? {
        let base = sessions.filter { abs($0.coefficient - 1.0) < 0.001 }
        guard base.count >= 2 else { return nil }
        let baseQ = average(base.map { Double($0.quality) })
        let others = Dictionary(grouping: sessions.filter { abs($0.coefficient - 1.0) >= 0.001 }) { roundCoefficient($0.coefficient) }
        guard let (k, v) = others.max(by: { average($0.value.map { Double($0.quality) }) < average($1.value.map { Double($0.quality) }) }),
              v.count >= 2
        else { return nil }
        let q = average(v.map { Double($0.quality) })
        let delta = ((q - baseQ) / max(baseQ, 0.01)) * 100
        let direction = delta >= 0 ? "higher" : "lower"
        return InsightItem(
            kind: .compareToBaseline,
            title: "Drift from 1×",
            message: "Average quality in \(label(k)) is about \(String(format: "%.0f", abs(delta)))% \(direction) than baseline (1×).",
            sampleCount: v.count,
            relatedCoefficient: k
        )
    }
}

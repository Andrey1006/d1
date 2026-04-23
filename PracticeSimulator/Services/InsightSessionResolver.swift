
import Foundation

enum InsightSessionResolver {
    static func sessions(for item: InsightItem, in pool: [PracticeSession]) -> [PracticeSession] {
        switch item.kind {
        case .lowData:
            return pool.sorted { $0.endedAt > $1.endedAt }
        case .baselineCalibration:
            return pool.filter { abs($0.coefficient - 1.0) < 0.001 }
                .sorted { $0.endedAt > $1.endedAt }
        case .bestQualityMode:
            guard let c = item.relatedCoefficient else { return [] }
            let rc = AnalyticsService.roundCoefficient(c)
            return pool.filter { AnalyticsService.roundCoefficient($0.coefficient) == rc }
                .sorted { $0.endedAt > $1.endedAt }
        case .fatigueQuality:
            let hi = pool.filter { $0.fatigue >= 7 }
            let lo = pool.filter { $0.fatigue <= 4 }
            return Array(Set(hi + lo)).sorted { $0.endedAt > $1.endedAt }
        case .compareToBaseline:
            guard let c = item.relatedCoefficient else { return [] }
            let rc = AnalyticsService.roundCoefficient(c)
            return pool.filter { AnalyticsService.roundCoefficient($0.coefficient) == rc }
                .sorted { $0.endedAt > $1.endedAt }
        case .continuePractice:
            return pool.sorted { $0.endedAt > $1.endedAt }
        }
    }
}

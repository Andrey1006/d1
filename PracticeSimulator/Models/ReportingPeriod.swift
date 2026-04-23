
import Foundation

enum ReportingPeriod: String, CaseIterable, Identifiable, Hashable, Codable {
    case week
    case month
    case threeMonths
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "Last 7 days"
        case .month: "Last 30 days"
        case .threeMonths: "Last 90 days"
        case .all: "All time"
        }
    }

    func contains(_ date: Date) -> Bool {
        if self == .all { return true }
        let days: Int
        switch self {
        case .week: days = 7
        case .month: days = 30
        case .threeMonths: days = 90
        case .all: return true
        }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return date >= start
    }
}

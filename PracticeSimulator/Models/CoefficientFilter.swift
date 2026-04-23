
import Foundation

enum CoefficientFilter: Hashable, Identifiable {
    case all
    case value(Double)

    var id: String {
        switch self {
        case .all: "all"
        case .value(let v): "v_\(v)"
        }
    }

    var title: String {
        switch self {
        case .all:
            return "All modes"
        case .value(let v):
            return PracticeCoefficient.presets.first { abs($0.value - v) < 0.001 }?.shortLabel ?? String(format: "%.2f×", v)
        }
    }
}

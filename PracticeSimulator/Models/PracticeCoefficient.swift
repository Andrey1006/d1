
import Foundation

struct PracticeCoefficient: Identifiable, Hashable, Codable {
    var id: Double { value }

    let value: Double
    let shortLabel: String
    let detail: String

    static let presets: [PracticeCoefficient] = [
        PracticeCoefficient(value: 0.7, shortLabel: "0.7×", detail: "Harder / slower"),
        PracticeCoefficient(value: 1.0, shortLabel: "1×", detail: "Baseline level"),
        PracticeCoefficient(value: 1.5, shortLabel: "1.5×", detail: "Faster / higher load"),
        PracticeCoefficient(value: 2.0, shortLabel: "2×", detail: "Intense mode"),
    ]

    static var baseline: PracticeCoefficient { presets.first { $0.value == 1.0 }! }
}


import Foundation

enum InsightKind: String, Codable, Hashable {
    case lowData
    case baselineCalibration
    case bestQualityMode
    case fatigueQuality
    case compareToBaseline
    case continuePractice
}

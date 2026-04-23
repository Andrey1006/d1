
import Foundation

struct PracticeSession: Identifiable, Codable, Hashable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date
    var practiceTypeId: UUID
    var coefficient: Double
    var durationSeconds: Int
    var difficulty: Int
    var concentration: Int
    var fatigue: Int
    var quality: Int
    var note: String
    var excludeFromAnalytics: Bool

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date = Date(),
        practiceTypeId: UUID,
        coefficient: Double,
        durationSeconds: Int,
        difficulty: Int,
        concentration: Int,
        fatigue: Int,
        quality: Int,
        note: String = "",
        excludeFromAnalytics: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.practiceTypeId = practiceTypeId
        self.coefficient = coefficient
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.concentration = concentration
        self.fatigue = fatigue
        self.quality = quality
        self.note = note
        self.excludeFromAnalytics = excludeFromAnalytics
    }
}

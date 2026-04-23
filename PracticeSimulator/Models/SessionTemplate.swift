
import Foundation

struct SessionTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var practiceTypeId: UUID
    var coefficient: Double
    var targetDurationSeconds: Int?

    init(
        id: UUID = UUID(),
        title: String,
        practiceTypeId: UUID,
        coefficient: Double,
        targetDurationSeconds: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.practiceTypeId = practiceTypeId
        self.coefficient = coefficient
        self.targetDurationSeconds = targetDurationSeconds
    }
}

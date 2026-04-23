
import Foundation

struct InsightItem: Identifiable, Hashable {
    let id: UUID
    let kind: InsightKind
    let title: String
    let message: String
    let sampleCount: Int
    let relatedCoefficient: Double?

    init(
        id: UUID = UUID(),
        kind: InsightKind,
        title: String,
        message: String,
        sampleCount: Int,
        relatedCoefficient: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.sampleCount = sampleCount
        self.relatedCoefficient = relatedCoefficient
    }
}

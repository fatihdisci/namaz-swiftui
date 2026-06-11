import Foundation
import SwiftData

@Model
final class KazaEntry {
    @Attribute(.unique) var id: UUID
    var prayer: Prayer
    /// Kazaya kalan namazın ait olduğu gün.
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        prayer: Prayer,
        date: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.prayer = prayer
        self.date = date
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

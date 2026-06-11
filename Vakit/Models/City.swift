import Foundation
import SwiftData

@Model
final class City {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var country: String
    var timezone: String
    var method: CalculationMethod
    /// Aladhan `school`: 0 = Shafi, 1 = Hanafi (Türkiye varsayılan)
    var school: Int
    var isPrimary: Bool

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        country: String,
        timezone: String,
        method: CalculationMethod = .diyanet,
        school: Int = 1,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.timezone = timezone
        self.method = method
        self.school = school
        self.isPrimary = isPrimary
    }
}

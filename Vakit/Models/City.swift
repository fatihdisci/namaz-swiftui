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
    /// Aladhan `school` / ikindi hesabı: 0 standart, 1 Hanefi.
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
        school: Int? = nil,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.timezone = timezone
        self.method = method
        let resolvedSchool = school ?? method.recommendedAsrCalculation.rawValue
        self.school = AsrCalculation(rawValue: resolvedSchool)?.rawValue ?? AsrCalculation.standard.rawValue
        self.isPrimary = isPrimary
    }
}

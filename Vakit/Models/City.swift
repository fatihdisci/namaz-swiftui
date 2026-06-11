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
    /// Aladhan `school` / Asr mezhebi: 0 = Standart (Şafi), 1 = Hanefi.
    /// Varsayılan 0 — Diyanet'in yayımladığı ikindi vakti standart Asr'dır;
    /// Hanefi'ye sabitlemek ikindiyi ~70+ dk geç gösterir. Kullanıcı seçimlidir.
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
        school: Int = 0,
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

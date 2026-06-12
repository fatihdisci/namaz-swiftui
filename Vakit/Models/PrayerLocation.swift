import Foundation

/// Kullanıcının seçtiği ibadet konumu.
/// Cascading seçim akışı: Ülke → Admin1 (İl/State) → Admin2 (İlçe/City).
/// Codable olduğu için UserDefaults/App Group'ta saklanabilir.
struct PrayerLocation: Codable, Equatable, Identifiable {
    let id: UUID
    var countryCode: String       // ISO 3166-1 alpha-2, örn. "TR", "US"
    var countryName: String       // Yerelleştirilmiş ülke adı
    var admin1Name: String        // TR: İl (İstanbul), US: State (California)
    var admin1Type: String        // "İl", "State", "Province", "Region"
    var admin2Name: String        // TR: İlçe (Kadıköy), US: City (Los Angeles)
    var admin2Type: String        // "İlçe", "City"
    var cityName: String          // Görünen şehir adı (admin1 veya admin2)
    var districtName: String      // TR için ilçe adı
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String
    var calculationMethod: CalculationMethod

    // MARK: - Init

    init(
        id: UUID = UUID(),
        countryCode: String,
        countryName: String,
        admin1Name: String = "",
        admin1Type: String = "",
        admin2Name: String = "",
        admin2Type: String = "",
        cityName: String = "",
        districtName: String = "",
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        calculationMethod: CalculationMethod = .diyanet
    ) {
        self.id = id
        self.countryCode = countryCode
        self.countryName = countryName
        self.admin1Name = admin1Name
        self.admin1Type = admin1Type
        self.admin2Name = admin2Name
        self.admin2Type = admin2Type
        self.cityName = cityName.isEmpty ? (admin1Name.isEmpty ? admin2Name : admin1Name) : cityName
        self.districtName = districtName
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calculationMethod = calculationMethod
    }

    // MARK: - Display

    /// UI'da gösterilecek kısa etiket: "Kadıköy, İstanbul" veya "Los Angeles, CA"
    var displayName: String {
        if !districtName.isEmpty {
            return "\(districtName), \(admin1Name)"
        } else if !admin2Name.isEmpty {
            return "\(admin2Name), \(admin1Name)"
        } else if !admin1Name.isEmpty {
            return "\(admin1Name), \(countryName)"
        } else {
            return cityName
        }
    }

    /// Sadece şehir/idari birim adı (liste gösterimi için).
    var shortName: String {
        if !districtName.isEmpty { return districtName }
        if !admin2Name.isEmpty { return admin2Name }
        if !admin1Name.isEmpty { return admin1Name }
        return cityName
    }

    /// Alt açıklama: "İstanbul, Türkiye" / "California, US"
    var subtitle: String {
        var parts: [String] = []
        if !admin1Name.isEmpty, admin1Name != shortName {
            parts.append(admin1Name)
        }
        if !countryName.isEmpty {
            parts.append(countryName)
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Bridge to City (prayer time calculation)

    /// Namaz vakti hesaplaması için geçici `City` örneği üretir.
    func makeCity(school: Int = 0) -> City {
        City(
            id: id,
            name: displayName,
            latitude: latitude,
            longitude: longitude,
            country: countryName,
            timezone: timeZoneIdentifier,
            method: calculationMethod,
            school: school,
            isPrimary: true
        )
    }

    // MARK: - Bridge to CitySnapshot (backward compat)

    func toSnapshot(school: Int = 0) -> CitySnapshot {
        CitySnapshot(
            id: id,
            name: displayName,
            latitude: latitude,
            longitude: longitude,
            country: countryName,
            timezone: timeZoneIdentifier,
            method: calculationMethod,
            school: school
        )
    }
}

// MARK: - Admin label helpers

extension PrayerLocation {
    /// Ülke koduna göre Admin1 (üst düzey idari birim) etiketi.
    /// TR: İl, US: State, CA: Province, GB: Region, DE: State, default: Region
    static func admin1Label(for countryCode: String) -> String {
        switch countryCode.uppercased() {
        case "TR": return String(localized: "location.admin1.tr")
        case "US": return String(localized: "location.admin1.us")
        case "CA": return String(localized: "location.admin1.ca")
        case "GB": return String(localized: "location.admin1.gb")
        case "DE": return String(localized: "location.admin1.de")
        default:   return String(localized: "location.admin1.default")
        }
    }

    /// Ülke koduna göre Admin2 (alt düzey idari birim) etiketi.
    /// TR: İlçe, diğer: City
    static func admin2Label(for countryCode: String) -> String {
        switch countryCode.uppercased() {
        case "TR": return String(localized: "location.admin2.tr")
        default:   return String(localized: "location.admin2.default")
        }
    }

    /// Ülke koduna göre varsayılan hesaplama metodu.
    static func defaultMethod(for countryCode: String) -> CalculationMethod {
        switch countryCode.uppercased() {
        case "TR": return .diyanet
        case "US", "CA": return .isna
        case "GB": return .mwl
        case "DE": return .mwl
        default:   return .mwl
        }
    }
}

import Foundation

/// Yerel JSON'dan konum verilerini yükleyen servis.
/// Şimdilik sadece Türkiye datası var; mimari yabancı ülkeler eklenebilecek şekilde.
final class LocationDataService {
    static let shared = LocationDataService()

    // MARK: - Türkiye veri modelleri (Decodable)

    private struct TurkeyData: Decodable {
        let countryCode: String
        let countryNameTR: String
        let countryNameEN: String
        let provinces: [ProvinceData]
    }

    private struct ProvinceData: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let timezone: String
        let districts: [DistrictData]
    }

    private struct DistrictData: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    // MARK: - Cached data

    private var turkeyData: TurkeyData?

    private init() {
        turkeyData = loadTurkeyData()
    }

    /// Cihaz bölgesinden ülke kodunu tahmin eder.
    /// `Locale.current.region?.identifier` → "TR", "US", vb.
    var detectedCountryCode: String {
        Locale.current.region?.identifier.uppercased() ?? "TR"
    }

    /// Tespit edilen ülke için yerel data var mı?
    var hasLocalData: Bool {
        let code = detectedCountryCode
        switch code {
        case "TR": return turkeyData != nil
        default:   return false
        }
    }

    /// Belirtilen ülke kodu için yerel data var mı?
    func hasLocalData(for countryCode: String) -> Bool {
        switch countryCode.uppercased() {
        case "TR": return turkeyData != nil
        default:   return false
        }
    }

    // MARK: - Ülke listesi

    /// Yerel datası olan ülkeleri döner (şimdilik sadece TR).
    /// Diğer ülkeler için Aladhan API üzerinden serbest metin araması kullanılır.
    func supportedCountries(language: String) -> [CountryOption] {
        var countries: [CountryOption] = []

        if let data = turkeyData {
            let name = language == "tr" ? data.countryNameTR : data.countryNameEN
            countries.append(CountryOption(
                code: data.countryCode,
                name: name,
                hasCascadingData: true
            ))
        }

        return countries
    }

    /// Tüm ülkeler (yerel data + yaygın ülkeler).
    func allCountries(language: String) -> [CountryOption] {
        var countries = supportedCountries(language: language)

        // Yerel datası olmayan yaygın ülkeler.
        let otherCodes = ["US", "GB", "DE", "FR", "CA", "AU", "SA", "AE", "QA", "KW", "OM", "BH"]
        let allCountryNames: [String: (tr: String, en: String)] = [
            "US": ("Amerika Birleşik Devletleri", "United States"),
            "GB": ("Birleşik Krallık", "United Kingdom"),
            "DE": ("Almanya", "Germany"),
            "FR": ("Fransa", "France"),
            "CA": ("Kanada", "Canada"),
            "AU": ("Avustralya", "Australia"),
            "SA": ("Suudi Arabistan", "Saudi Arabia"),
            "AE": ("Birleşik Arap Emirlikleri", "United Arab Emirates"),
            "QA": ("Katar", "Qatar"),
            "KW": ("Kuveyt", "Kuwait"),
            "OM": ("Umman", "Oman"),
            "BH": ("Bahreyn", "Bahrain"),
        ]

        for code in otherCodes where !countries.contains(where: { $0.code == code }) {
            if let names = allCountryNames[code] {
                countries.append(CountryOption(
                    code: code,
                    name: language == "tr" ? names.tr : names.en,
                    hasCascadingData: false
                ))
            }
        }

        return countries
    }

    // MARK: - Türkiye sorguları

    /// Türkiye'deki tüm illeri döner.
    func turkeyProvinces() -> [AdminUnit] {
        guard let data = turkeyData else { return [] }
        return data.provinces.map { province in
            AdminUnit(
                name: province.name,
                latitude: province.latitude,
                longitude: province.longitude,
                timezone: province.timezone
            )
        }
    }

    /// Belirtilen ilin ilçelerini döner.
    func turkeyDistricts(for provinceName: String) -> [AdminUnit] {
        guard
            let data = turkeyData,
            let province = data.provinces.first(where: { $0.name == provinceName })
        else { return [] }
        return province.districts.map { district in
            AdminUnit(
                name: district.name,
                latitude: district.latitude,
                longitude: district.longitude,
                timezone: province.timezone
            )
        }
    }

    /// İl adından enlem/boylam/timezone
    func turkeyProvince(_ name: String) -> AdminUnit? {
        turkeyProvinces().first { $0.name == name }
    }

    /// İlçe adından enlem/boylam/timezone (il bağlamında)
    func turkeyDistrict(provinceName: String, districtName: String) -> AdminUnit? {
        turkeyDistricts(for: provinceName).first { $0.name == districtName }
    }

    // MARK: - Load

    private func loadTurkeyData() -> TurkeyData? {
        guard let url = Bundle.main.url(forResource: "turkey_locations", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(TurkeyData.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Yardımcı tipler

/// UI seçim listesi için idari birim.
struct AdminUnit: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let timezone: String
}

/// Ülke seçenek listesi elemanı.
struct CountryOption: Identifiable, Equatable {
    let id: String  // ISO code
    var code: String { id }
    let name: String
    let hasCascadingData: Bool  // true → yerel data ile cascading seçim, false → serbest arama
}

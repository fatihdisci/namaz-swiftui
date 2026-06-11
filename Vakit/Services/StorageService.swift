import Foundation

/// App Group UserDefaults sarmalayıcısı.
/// Vakit cache'i + basit ayarlar (şehir, metod, dil, onboarding) burada yaşar.
/// Widget ile paylaşım `group.com.fatihdisci.vakit.shared` üzerinden olur.
final class StorageService {
    static let shared = StorageService()

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private enum Key {
        static let timesPrefix = "times_"
        static let selectedCityID = "selected_city_id"
        static let selectedCity = "selected_city"
        static let method = "method"
        static let language = "language"
        static let onboardingDone = "onboarding_done"
        static let notificationSettings = "notification_settings"
    }

    private static let cacheRetentionDays = 30

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(defaults: UserDefaults = AppGroup.userDefaults) {
        self.defaults = defaults

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Vakit Cache

    static func dateKey(for date: Date) -> String {
        dateKeyFormatter.string(from: date)
    }

    private func cacheKey(for date: Date) -> String {
        Key.timesPrefix + Self.dateKey(for: date)
    }

    func cachedPrayerTimes(for date: Date) -> CachedPrayerTimes? {
        pruneExpiredCache()
        guard let data = defaults.data(forKey: cacheKey(for: date)) else { return nil }
        return try? decoder.decode(CachedPrayerTimes.self, from: data)
    }

    func cachePrayerTimes(_ cached: CachedPrayerTimes, for date: Date) {
        guard let data = try? encoder.encode(cached) else { return }
        defaults.set(data, forKey: cacheKey(for: date))
        pruneExpiredCache()
    }

    /// 30 günden eski cache kayıtlarını temizler.
    func pruneExpiredCache() {
        guard let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -Self.cacheRetentionDays,
            to: Calendar.current.startOfDay(for: Date())
        ) else { return }

        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(Key.timesPrefix) {
            let dateKey = String(key.dropFirst(Key.timesPrefix.count))
            guard let cacheDate = Self.dateKeyFormatter.date(from: dateKey) else {
                defaults.removeObject(forKey: key)
                continue
            }
            if cacheDate < cutoff {
                defaults.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Ayarlar

    var selectedCityID: UUID? {
        get { defaults.string(forKey: Key.selectedCityID).flatMap(UUID.init(uuidString:)) }
        set { defaults.set(newValue?.uuidString, forKey: Key.selectedCityID) }
    }

    /// Seçili şehrin Codable kopyası. Widget ve ViewModel'ler SwiftData context'i
    /// olmadan da şehre erişebilsin diye App Group'ta tutulur.
    var selectedCity: CitySnapshot? {
        get {
            guard let data = defaults.data(forKey: Key.selectedCity) else { return nil }
            return try? decoder.decode(CitySnapshot.self, from: data)
        }
        set {
            if let newValue, let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Key.selectedCity)
            } else {
                defaults.removeObject(forKey: Key.selectedCity)
            }
        }
    }

    var method: CalculationMethod {
        get {
            guard defaults.object(forKey: Key.method) != nil else { return .default }
            return CalculationMethod(rawValue: defaults.integer(forKey: Key.method)) ?? .default
        }
        set { defaults.set(newValue.rawValue, forKey: Key.method) }
    }

    /// "tr" veya "en"
    var language: String {
        get { defaults.string(forKey: Key.language) ?? Self.deviceDefaultLanguage }
        set { defaults.set(newValue, forKey: Key.language) }
    }

    private static var deviceDefaultLanguage: String {
        Locale.preferredLanguages.first?.hasPrefix("tr") == true ? "tr" : "en"
    }

    var onboardingDone: Bool {
        get { defaults.bool(forKey: Key.onboardingDone) }
        set { defaults.set(newValue, forKey: Key.onboardingDone) }
    }

    /// Vakit bazlı bildirim ayarları. Kayıtlı değer yoksa veya bozuksa varsayılana döner.
    var notificationSettings: NotificationSettings {
        get {
            guard let data = defaults.data(forKey: Key.notificationSettings) else { return .default }
            return (try? decoder.decode(NotificationSettings.self, from: data)) ?? .default
        }
        set {
            guard let data = try? encoder.encode(newValue) else { return }
            defaults.set(data, forKey: Key.notificationSettings)
        }
    }

    // MARK: - Hicri Tarih (offline)

    /// Offline hicri tarih: `Calendar(identifier: .islamicUmmAlQura)` ile hesaplanır.
    /// Ay ismi İngilizce sembol olarak döner (örn. "Ramadan"); UI lokalizasyonu ileride
    /// String Catalog üzerinden yapılır.
    func offlineHijri(for date: Date) -> (day: String, monthName: String, year: String) {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "en")

        let components = calendar.dateComponents([.day, .month, .year], from: date)

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en")
        let monthSymbols = formatter.monthSymbols ?? []

        let monthIndex = (components.month ?? 1) - 1
        let monthName = monthSymbols.indices.contains(monthIndex) ? monthSymbols[monthIndex] : ""

        return (
            day: String(components.day ?? 1),
            monthName: monthName,
            year: String(components.year ?? 1)
        )
    }
}

/// Seçili şehrin hafif Codable kopyası (SwiftData `City` modelinden bağımsız).
struct CitySnapshot: Codable, Equatable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var country: String
    var timezone: String
    var method: CalculationMethod
    var school: Int

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        country: String,
        timezone: String,
        method: CalculationMethod = .diyanet,
        school: Int = 1
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.timezone = timezone
        self.method = method
        self.school = school
    }

    init(city: City) {
        self.init(
            id: city.id,
            name: city.name,
            latitude: city.latitude,
            longitude: city.longitude,
            country: city.country,
            timezone: city.timezone,
            method: city.method,
            school: city.school
        )
    }

    /// SwiftData context'ine bağlı olmayan geçici bir `City` örneği üretir.
    func makeCity() -> City {
        City(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            country: country,
            timezone: timezone,
            method: method,
            school: school
        )
    }
}

/// Cache'e yazılan kayıt: vakitler + isteğin parametreleri.
/// Parametreler değişmişse (şehir/metod/okul) cache geçersiz sayılır.
struct CachedPrayerTimes: Codable {
    let times: PrayerTimes
    let latitude: Double
    let longitude: Double
    let method: Int
    let school: Int
    let cachedAt: Date

    func matches(latitude: Double, longitude: Double, method: Int, school: Int) -> Bool {
        self.method == method
            && self.school == school
            && abs(self.latitude - latitude) < 0.0001
            && abs(self.longitude - longitude) < 0.0001
    }
}

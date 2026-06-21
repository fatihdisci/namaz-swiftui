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
        static let prayerLocation = "prayer_location"
        static let savedPrayerLocations = "saved_prayer_locations"
        static let homePrayerLocation = "home_prayer_location"
        static let method = "method"
        static let school = "school"
        static let language = "language"
        static let onboardingDone = "onboarding_done"
        static let notificationSettings = "notification_settings"
        static let kazaCounts = "kaza_counts"
        static let favoriteDuaIDs = "favorite_dua_ids"
        static let fridayReminderEnabled = "friday_reminder_enabled"
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

    /// Yeni veya eski modelden `City` üretir (HomeViewModel, bildirimler vs. için).
    var resolvedCity: City? {
        if let location = selectedPrayerLocation {
            return location.makeCity()
        }
        return selectedCity?.makeCity()
    }

    var selectedCityID: UUID? {
        get { defaults.string(forKey: Key.selectedCityID).flatMap(UUID.init(uuidString:)) }
        set { defaults.set(newValue?.uuidString, forKey: Key.selectedCityID) }
    }

    /// Seçili şehrin Codable kopyası. Widget ve ViewModel'ler SwiftData context'i
    /// olmadan da şehre erişebilsin diye App Group'ta tutulur.
    var selectedCity: CitySnapshot? {
        get {
            // Önce yeni PrayerLocation modelini dene, yoksa eski snapshot'a düş.
            if let prayerLoc = selectedPrayerLocation {
                return prayerLoc.toSnapshot()
            }
            return legacySelectedCitySnapshot
        }
        set {
            if let newValue, let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Key.selectedCity)
            } else {
                defaults.removeObject(forKey: Key.selectedCity)
            }
        }
    }

    /// Yeni cascading konum seçimi modeli.
    /// Kaydedildiğinde eski `selectedCity` ile senkronize edilir.
    var selectedPrayerLocation: PrayerLocation? {
        get {
            if let data = defaults.data(forKey: Key.prayerLocation) {
                return try? decoder.decode(PrayerLocation.self, from: data)
            }
            return legacySelectedCitySnapshot.map { snapshot in
                PrayerLocation(
                    id: snapshot.id,
                    countryCode: "",
                    countryName: snapshot.country,
                    admin1Name: snapshot.name,
                    admin1Type: "",
                    admin2Name: "",
                    admin2Type: "",
                    cityName: snapshot.name,
                    districtName: "",
                    latitude: snapshot.latitude,
                    longitude: snapshot.longitude,
                    timeZoneIdentifier: snapshot.timezone,
                    calculationMethod: snapshot.method
                )
            }
        }
        set {
            if let newValue, let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Key.prayerLocation)
                // Eski selectedCity ve selectedCityID'yi de güncelle (geriye uyumluluk).
                let snapshot = newValue.toSnapshot()
                if let snapData = try? encoder.encode(snapshot) {
                    defaults.set(snapData, forKey: Key.selectedCity)
                }
                defaults.set(newValue.id.uuidString, forKey: Key.selectedCityID)
                method = newValue.calculationMethod
                school = newValue.school
                addOrUpdateSavedPrayerLocation(newValue)
                if homePrayerLocation == nil {
                    homePrayerLocation = newValue
                }
            } else {
                defaults.removeObject(forKey: Key.prayerLocation)
                defaults.removeObject(forKey: Key.selectedCity)
                defaults.removeObject(forKey: Key.selectedCityID)
            }
            notifyPrayerLocationChanged()
        }
    }

    var savedPrayerLocations: [PrayerLocation] {
        get {
            guard let data = defaults.data(forKey: Key.savedPrayerLocations) else {
                if let selectedPrayerLocation { return [selectedPrayerLocation] }
                return []
            }
            return (try? decoder.decode([PrayerLocation].self, from: data)) ?? []
        }
        set {
            guard let data = try? encoder.encode(Self.uniqueLocations(newValue)) else { return }
            defaults.set(data, forKey: Key.savedPrayerLocations)
            notifySavedPrayerLocationsChanged()
        }
    }

    var homePrayerLocation: PrayerLocation? {
        get {
            guard let data = defaults.data(forKey: Key.homePrayerLocation) else { return nil }
            return try? decoder.decode(PrayerLocation.self, from: data)
        }
        set {
            if let newValue, let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Key.homePrayerLocation)
            } else {
                defaults.removeObject(forKey: Key.homePrayerLocation)
            }
            notifyHomePrayerLocationChanged()
        }
    }

    func addOrUpdateSavedPrayerLocation(_ location: PrayerLocation) {
        var locations = savedPrayerLocations
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
        } else {
            locations.append(location)
        }
        guard let data = try? encoder.encode(Self.uniqueLocations(locations)) else { return }
        defaults.set(data, forKey: Key.savedPrayerLocations)
        notifySavedPrayerLocationsChanged()
    }

    func removeSavedPrayerLocation(id: UUID) {
        var locations = savedPrayerLocations.filter { $0.id != id }
        if locations.isEmpty, let selectedPrayerLocation {
            locations = [selectedPrayerLocation]
        }
        savedPrayerLocations = locations
    }

    var method: CalculationMethod {
        get {
            guard defaults.object(forKey: Key.method) != nil else { return .default }
            return CalculationMethod(rawValue: defaults.integer(forKey: Key.method)) ?? .default
        }
        set { defaults.set(newValue.rawValue, forKey: Key.method) }
    }

    /// İkindi hesabı: 0 = standart, 1 = Hanefi.
    var school: Int {
        get {
            AsrCalculation(rawValue: defaults.integer(forKey: Key.school))?.rawValue
                ?? AsrCalculation.standard.rawValue
        }
        set {
            let validValue = AsrCalculation(rawValue: newValue)?.rawValue
                ?? AsrCalculation.standard.rawValue
            defaults.set(validValue, forKey: Key.school)
        }
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

    var favoriteDuaIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Key.favoriteDuaIDs) ?? []) }
        set { defaults.set(Array(newValue).sorted(), forKey: Key.favoriteDuaIDs) }
    }

    func toggleFavoriteDua(id: String) {
        var ids = favoriteDuaIDs
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        favoriteDuaIDs = ids
    }

    var fridayReminderEnabled: Bool {
        get {
            guard defaults.object(forKey: Key.fridayReminderEnabled) != nil else { return false }
            return defaults.bool(forKey: Key.fridayReminderEnabled)
        }
        set { defaults.set(newValue, forKey: Key.fridayReminderEnabled) }
    }

    /// Beş farz vakit için kullanıcının girdiği kaza adetleri.
    var kazaCounts: KazaCounts {
        get {
            guard let data = defaults.data(forKey: Key.kazaCounts) else { return .empty }
            return (try? decoder.decode(KazaCounts.self, from: data)) ?? .empty
        }
        set {
            guard let data = try? encoder.encode(newValue) else { return }
            defaults.set(data, forKey: Key.kazaCounts)
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

    private static func uniqueLocations(_ locations: [PrayerLocation]) -> [PrayerLocation] {
        var seen: Set<UUID> = []
        return locations.filter { location in
            if seen.contains(location.id) { return false }
            seen.insert(location.id)
            return true
        }
    }

    private var legacySelectedCitySnapshot: CitySnapshot? {
        guard let data = defaults.data(forKey: Key.selectedCity) else { return nil }
        return try? decoder.decode(CitySnapshot.self, from: data)
    }

    private func notifyPrayerLocationChanged() {
        NotificationCenter.default.post(name: .vakitPrayerLocationChanged, object: nil)
    }

    private func notifySavedPrayerLocationsChanged() {
        NotificationCenter.default.post(name: .vakitSavedPrayerLocationsChanged, object: nil)
    }

    private func notifyHomePrayerLocationChanged() {
        NotificationCenter.default.post(name: .vakitHomePrayerLocationChanged, object: nil)
    }
}

extension StorageService {
    /// Hesap silme için: kullanıcıya ait TÜM yerel veriyi App Group'tan temizler.
    /// Konum, kaza, bildirim ayarları, önbellek ve onboarding sıfırlanır.
    /// Dil tercihi (cihaz geneli bir tercih) korunur.
    func wipeUserData() {
        let keysToRemove = [
            Key.selectedCityID,
            Key.selectedCity,
            Key.prayerLocation,
            Key.savedPrayerLocations,
            Key.homePrayerLocation,
            Key.method,
            Key.school,
            Key.onboardingDone,
            Key.notificationSettings,
            Key.kazaCounts,
            Key.favoriteDuaIDs,
            Key.fridayReminderEnabled,
        ]
        keysToRemove.forEach { defaults.removeObject(forKey: $0) }

        // Önbelleğe alınmış tüm vakit kayıtlarını (times_*) sil.
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(Key.timesPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}

extension Notification.Name {
    static let vakitPrayerLocationChanged = Notification.Name("vakitPrayerLocationChanged")
    static let vakitSavedPrayerLocationsChanged = Notification.Name("vakitSavedPrayerLocationsChanged")
    static let vakitHomePrayerLocationChanged = Notification.Name("vakitHomePrayerLocationChanged")
    /// Hesap silindiğinde gönderilir; app onboarding'e döner.
    static let vakitAccountDeleted = Notification.Name("vakitAccountDeleted")
}

struct KazaCounts: Codable, Equatable {
    var fajr = 0
    var dhuhr = 0
    var asr = 0
    var maghrib = 0
    var isha = 0

    static let empty = KazaCounts()

    var total: Int {
        fajr + dhuhr + asr + maghrib + isha
    }

    subscript(prayer: Prayer) -> Int {
        get {
            switch prayer {
            case .fajr: fajr
            case .dhuhr: dhuhr
            case .asr: asr
            case .maghrib: maghrib
            case .isha: isha
            case .sunrise: 0
            }
        }
        set {
            let value = max(0, newValue)
            switch prayer {
            case .fajr: fajr = value
            case .dhuhr: dhuhr = value
            case .asr: asr = value
            case .maghrib: maghrib = value
            case .isha: isha = value
            case .sunrise: break
            }
        }
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
        school: Int = 0
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

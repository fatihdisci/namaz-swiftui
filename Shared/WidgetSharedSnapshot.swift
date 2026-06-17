import Foundation

/// Ana uygulama ile Home Screen widget'ı arasında App Group üzerinden paylaşılan
/// küçük, stabil namaz vakti anlık görüntüsü.
///
/// Bu model bilerek SwiftData / servis / CoreLocation / RevenueCat'ten BAĞIMSIZDIR.
/// Hem ana app hem de widget target'ı tarafından derlenir; widget sadece bu
/// snapshot'ı App Group'tan okuyup render eder.
struct WidgetPrayerSnapshot: Codable, Equatable {
    struct Row: Codable, Equatable {
        /// Prayer.rawValue: "fajr","sunrise","dhuhr","asr","maghrib","isha"
        let prayerKey: String
        let time: Date
    }

    let cityName: String        // Tam görünen ad, örn. "Kadıköy, İstanbul"
    let shortCityName: String   // Kısa ad (widget small için), örn. "Kadıköy"
    let countryName: String
    let date: Date              // Bugünün günü (startOfDay)
    let hijriDate: String       // "12 Ramadan 1447"
    let rows: [Row]             // Bugünün 6 vakti, sırayla
    let tomorrowFajr: Date?     // Yatsıdan sonra "sıradaki" için (yarının sabahı)
    let language: String        // "tr" / "en"
    let accentPrayerKey: String // Snapshot üretildiği andaki sıradaki vakit
    let generatedAt: Date

    init(
        cityName: String,
        shortCityName: String,
        countryName: String,
        date: Date,
        hijriDate: String,
        rows: [Row],
        tomorrowFajr: Date?,
        language: String,
        accentPrayerKey: String,
        generatedAt: Date = Date()
    ) {
        self.cityName = cityName
        self.shortCityName = shortCityName
        self.countryName = countryName
        self.date = date
        self.hijriDate = hijriDate
        self.rows = rows
        self.tomorrowFajr = tomorrowFajr
        self.language = language
        self.accentPrayerKey = accentPrayerKey
        self.generatedAt = generatedAt
    }
}

// MARK: - Sıradaki vakit yardımcıları (her iki target da kullanır)

extension WidgetPrayerSnapshot {
    /// Verilen andan sonraki ilk vakit. Bugünün tüm vakitleri geçtiyse yarının sabahı.
    func next(after date: Date) -> (key: String, time: Date)? {
        if let row = rows.first(where: { $0.time > date }) {
            return (row.prayerKey, row.time)
        }
        if let tomorrowFajr {
            return ("fajr", tomorrowFajr)
        }
        return nil
    }

    /// Timeline entry sınırları için: verilen andan sonraki tüm vakit zamanları.
    func upcomingTimes(after date: Date) -> [Date] {
        var times = rows.map(\.time).filter { $0 > date }
        if let tomorrowFajr, tomorrowFajr > date {
            times.append(tomorrowFajr)
        }
        return times.sorted()
    }
}

// MARK: - App Group store

/// App Group UserDefaults üzerinde snapshot okuma/yazma.
enum WidgetSnapshotStore {
    static let key = "widget_prayer_snapshot_v1"

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func save(_ snapshot: WidgetPrayerSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        AppGroup.userDefaults.set(data, forKey: key)
    }

    static func load() -> WidgetPrayerSnapshot? {
        guard let data = AppGroup.userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(WidgetPrayerSnapshot.self, from: data)
    }

    static func clear() {
        AppGroup.userDefaults.removeObject(forKey: key)
    }
}

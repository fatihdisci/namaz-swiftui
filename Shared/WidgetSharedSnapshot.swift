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
    let tomorrowRows: [Row]     // Yarın için 6 vakit; widget gece yarısından sonra bayatlamasın
    let tomorrowFajr: Date?     // Geriye uyumluluk: eski snapshot'larda sadece yarının sabahı
    let language: String        // "tr" / "en"
    let accentPrayerKey: String // Snapshot üretildiği andaki sıradaki vakit
    let dailyVerseText: String?     // Widget Medium için günlük ayet/hadis teaser'ı
    let dailyVerseReference: String? // Kaynak referansı (örn. "Bakara · 255")
    let generatedAt: Date

    init(
        cityName: String,
        shortCityName: String,
        countryName: String,
        date: Date,
        hijriDate: String,
        rows: [Row],
        tomorrowRows: [Row] = [],
        tomorrowFajr: Date?,
        language: String,
        accentPrayerKey: String,
        dailyVerseText: String? = nil,
        dailyVerseReference: String? = nil,
        generatedAt: Date = Date()
    ) {
        self.cityName = cityName
        self.shortCityName = shortCityName
        self.countryName = countryName
        self.date = date
        self.hijriDate = hijriDate
        self.rows = rows
        self.tomorrowRows = tomorrowRows
        self.tomorrowFajr = tomorrowFajr
        self.language = language
        self.accentPrayerKey = accentPrayerKey
        self.dailyVerseText = dailyVerseText
        self.dailyVerseReference = dailyVerseReference
        self.generatedAt = generatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case cityName, shortCityName, countryName, date, hijriDate
        case rows, tomorrowRows, tomorrowFajr, language, accentPrayerKey
        case dailyVerseText, dailyVerseReference, generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cityName = try container.decode(String.self, forKey: .cityName)
        shortCityName = try container.decode(String.self, forKey: .shortCityName)
        countryName = try container.decode(String.self, forKey: .countryName)
        date = try container.decode(Date.self, forKey: .date)
        hijriDate = try container.decode(String.self, forKey: .hijriDate)
        rows = try container.decode([Row].self, forKey: .rows)
        tomorrowRows = try container.decodeIfPresent([Row].self, forKey: .tomorrowRows) ?? []
        tomorrowFajr = try container.decodeIfPresent(Date.self, forKey: .tomorrowFajr)
        language = try container.decode(String.self, forKey: .language)
        accentPrayerKey = try container.decode(String.self, forKey: .accentPrayerKey)
        dailyVerseText = try container.decodeIfPresent(String.self, forKey: .dailyVerseText)
        dailyVerseReference = try container.decodeIfPresent(String.self, forKey: .dailyVerseReference)
        generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date.distantPast
    }
}

// MARK: - Sıradaki vakit yardımcıları (her iki target da kullanır)

extension WidgetPrayerSnapshot {
    /// Bugün + yarın satırları tek kronolojik akış. Eski snapshot'lar için `tomorrowFajr`
    /// yedek olarak eklenir; böylece gece yarısından sonra en azından yarın imsak doğru kalır.
    var chronologicalRows: [Row] {
        var combined = rows + tomorrowRows
        if tomorrowRows.isEmpty, let tomorrowFajr {
            combined.append(Row(prayerKey: "fajr", time: tomorrowFajr))
        }
        return combined.sorted { $0.time < $1.time }
    }

    /// Verilen andan sonraki ilk vakit. Bugünün tüm vakitleri geçtiyse yarının vakitlerine geçer.
    func next(after date: Date) -> (key: String, time: Date)? {
        chronologicalRows.first { $0.time > date }.map { ($0.prayerKey, $0.time) }
    }

    /// Timeline entry sınırları için: verilen andan sonraki tüm vakit zamanları.
    func upcomingTimes(after date: Date) -> [Date] {
        chronologicalRows.map(\.time).filter { $0 > date }
    }

    /// Verilen andaki "önceki → sonraki" vakit penceresi.
    /// Progress halkası bu vakit aralığının ne kadarının geçtiğini gösterir.
    func window(at now: Date) -> (previous: Date, next: (key: String, time: Date))? {
        guard let next = next(after: now) else { return nil }
        let sorted = chronologicalRows

        if let previous = sorted.last(where: { $0.time <= now }) {
            return (previous.time, next)
        }
        // Snapshot'ın ilk vaktinden önce: önceki sınır ≈ bir önceki günün yatsısı.
        if let isha = rows.first(where: { $0.prayerKey == "isha" }) {
            return (isha.time.addingTimeInterval(-24 * 3600), next)
        }
        return (now.addingTimeInterval(-3600), next)
    }

    /// 0...1 dolum oranı.
    func progress(at now: Date) -> Double {
        guard let window = window(at: now) else { return 0 }
        let total = window.next.time.timeIntervalSince(window.previous)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(window.previous) / total))
    }

    /// WidgetKit timeline girişleri: periyodik tazeleme + tam vakit değişim anları.
    func timelineEntryDates(from now: Date, horizon: TimeInterval = 24 * 60 * 60) -> [Date] {
        var dates: [Date] = [now]
        var cursor = now
        let end = now.addingTimeInterval(horizon)
        while cursor < end {
            cursor = cursor.addingTimeInterval(15 * 60)
            dates.append(cursor)
        }
        dates.append(contentsOf: upcomingTimes(after: now).filter { $0 <= end })
        return Array(Set(dates)).filter { $0 >= now }.sorted()
    }

    /// Gökyüzü fazı için verilen anda geçerli günün satırları.
    func rowsForSkyPhase(at now: Date) -> [Row] {
        if let fajr = rows.first(where: { $0.prayerKey == "fajr" })?.time,
           let nextFajr = tomorrowRows.first(where: { $0.prayerKey == "fajr" })?.time,
           now >= nextFajr || now < fajr {
            return tomorrowRows.isEmpty ? rows : tomorrowRows
        }
        return rows
    }
}

// MARK: - Hicri ay adı normalizasyonu

extension String {
    /// Hicri ay adındaki aksanları temizler: "Muḥarram" -> "Muharram".
    /// Ana app ile aynı davranış (PrayerTimeService.displayHijriMonthName).
    var hijriDiacriticStripped: String {
        folding(options: [.diacriticInsensitive], locale: Locale(identifier: "en"))
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

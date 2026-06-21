import Foundation

enum PrayerTimeSource: String, Codable, Equatable {
    case aladhan
    case localCalculation
    case estimated

    var isReliableForNotifications: Bool { self != .estimated }
}

/// Bir günün 6 namaz vakti + hicri tarih.
struct PrayerTimes: Codable, Equatable {
    /// Vakitlerin ait olduğu (miladi) gün.
    let date: Date

    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date

    // Hicri tarih
    let hijriDay: String
    let hijriMonthName: String
    let hijriYear: String

    /// Saatlerin hangi veri yolundan üretildiği. Eski cache kayıtları `aladhan` kabul edilir.
    let source: PrayerTimeSource

    init(
        date: Date,
        fajr: Date,
        sunrise: Date,
        dhuhr: Date,
        asr: Date,
        maghrib: Date,
        isha: Date,
        hijriDay: String,
        hijriMonthName: String,
        hijriYear: String,
        source: PrayerTimeSource = .aladhan
    ) {
        self.date = date
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.hijriDay = hijriDay
        self.hijriMonthName = hijriMonthName
        self.hijriYear = hijriYear
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case date, fajr, sunrise, dhuhr, asr, maghrib, isha
        case hijriDay, hijriMonthName, hijriYear, source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        fajr = try container.decode(Date.self, forKey: .fajr)
        sunrise = try container.decode(Date.self, forKey: .sunrise)
        dhuhr = try container.decode(Date.self, forKey: .dhuhr)
        asr = try container.decode(Date.self, forKey: .asr)
        maghrib = try container.decode(Date.self, forKey: .maghrib)
        isha = try container.decode(Date.self, forKey: .isha)
        hijriDay = try container.decode(String.self, forKey: .hijriDay)
        hijriMonthName = try container.decode(String.self, forKey: .hijriMonthName)
        hijriYear = try container.decode(String.self, forKey: .hijriYear)
        source = try container.decodeIfPresent(PrayerTimeSource.self, forKey: .source) ?? .aladhan
    }

    var isReliableForNotifications: Bool { source.isReliableForNotifications }

    var isRamadan: Bool {
        let normalized = hijriMonthName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en"))
        return normalized == "ramadan" || normalized == "ramazan"
    }

    func time(for prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: return fajr
        case .sunrise: return sunrise
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }

    /// Gün içi sırada (vakit, saat) çiftleri.
    var orderedTimes: [(prayer: Prayer, time: Date)] {
        Prayer.allCases.map { ($0, time(for: $0)) }
    }
}

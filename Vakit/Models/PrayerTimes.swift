import Foundation

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

import SwiftUI

enum Prayer: String, CaseIterable, Identifiable, Codable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .fajr: return .fajr
        case .sunrise: return .sunrise
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        }
    }

    var localizationKey: String {
        switch self {
        case .fajr: return "prayer.fajr"
        case .sunrise: return "prayer.sunrise"
        case .dhuhr: return "prayer.dhuhr"
        case .asr: return "prayer.asr"
        case .maghrib: return "prayer.maghrib"
        case .isha: return "prayer.isha"
        }
    }

    var systemImage: String {
        switch self {
        case .fajr: return "moon.stars.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.min.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.fill"
        }
    }
}

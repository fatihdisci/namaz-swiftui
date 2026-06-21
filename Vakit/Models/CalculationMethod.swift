import Foundation

/// Aladhan API hesaplama metodları. Raw value = Aladhan `method` parametresi.
/// Kaynak: https://aladhan.com/calculation-methods
enum CalculationMethod: Int, CaseIterable, Codable, Identifiable {
    case diyanet = 13
    case mwl = 3
    case isna = 2
    case ummAlQura = 4
    case egyptian = 5

    static let `default`: CalculationMethod = .diyanet

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .diyanet: return "Diyanet"
        case .mwl: return "Muslim World League"
        case .isna: return "ISNA"
        case .ummAlQura: return "Umm al-Qura"
        case .egyptian: return "Egyptian"
        }
    }

    var localizationKey: String {
        switch self {
        case .diyanet: return "method.diyanet"
        case .mwl: return "method.mwl"
        case .isna: return "method.isna"
        case .ummAlQura: return "method.ummAlQura"
        case .egyptian: return "method.egyptian"
        }
    }
}

/// İkindi vaktinin gölge uzunluğu hesabı. Raw value Aladhan `school` parametresidir.
enum AsrCalculation: Int, CaseIterable, Codable, Identifiable {
    case standard = 0
    case hanafi = 1

    var id: Int { rawValue }

    var localizationKey: String {
        switch self {
        case .standard: return "school.standard"
        case .hanafi: return "school.hanafi"
        }
    }
}

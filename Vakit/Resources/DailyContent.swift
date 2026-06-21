import Foundation

// MARK: - İçerik modelleri (Resources/Content/*.json şeması)

/// Günün ayeti. JSON alan adları veri sözleşmesidir (Türkçe anahtarlar).
struct Verse: Codable, Identifiable, Equatable {
    let id: String
    let arabic: String?
    let textTR: String
    let textEN: String
    let surahName: String
    let surahNumber: Int
    let verseNumber: String
    let source: String
    let referenceURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case arabic = "arapca"
        case textTR = "turkce"
        case textEN = "ingilizce"
        case surahName = "sureAdi"
        case surahNumber = "sureNo"
        case verseNumber = "ayetNo"
        case source = "kaynak"
        case referenceURL = "atifUrl"
    }

    /// "Bakara · 45" biçiminde referans.
    var reference: String { "\(surahName) · \(verseNumber)" }

    func text(language: String) -> String {
        language == "tr" ? textTR : textEN
    }
}

/// Günün hadisi. `grade`: sahihlik derecesi (Sahih/Hasen...).
struct Hadith: Codable, Identifiable, Equatable {
    let id: String
    let textTR: String
    let textEN: String
    let source: String
    let grade: String
    let referenceURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case textTR = "metin_tr"
        case textEN = "metin_en"
        case source = "kaynak"
        case grade = "derece"
        case referenceURL = "atifUrl"
    }

    func text(language: String) -> String {
        language == "tr" ? textTR : textEN
    }
}

/// Günün duası. `kind`: "kurani" (ayet duası) veya "nebevi" (hadis duası).
struct Dua: Codable, Identifiable, Equatable {
    let id: String
    let kind: String
    let arabic: String?
    let transliteration: String?
    let textTR: String
    let textEN: String
    let source: String
    let grade: String?
    let referenceURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case kind = "tip"
        case arabic = "arapca"
        case transliteration = "okunus"
        case textTR = "turkce"
        case textEN = "ingilizce"
        case source = "kaynak"
        case grade = "derece"
        case referenceURL = "atifUrl"
    }

    func text(language: String) -> String {
        language == "tr" ? textTR : textEN
    }

    var category: DuaCategory {
        switch id {
        case "d003", "d010", "d012": return .calm
        case "d004", "d005", "d009", "d014": return .success
        case "d002", "d006", "d007": return .forgiveness
        case "d008", "d013", "d015": return .family
        case "d001", "d011": return .gratitude
        default: return .other
        }
    }

    func matches(_ query: String, language: String) -> Bool {
        let normalized = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard !normalized.isEmpty else { return true }
        return [text(language: language), source, transliteration ?? ""]
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .contains(normalized)
    }
}

enum DuaCategory: String, CaseIterable, Identifiable {
    case all
    case calm
    case success
    case forgiveness
    case family
    case gratitude
    case other

    var id: String { rawValue }
    var localizationKey: String { "dua.category.\(rawValue)" }

    func contains(_ dua: Dua) -> Bool {
        self == .all || dua.category == self
    }
}

/// Esmaül Hüsna (99 isim).
struct EsmaName: Codable, Identifiable, Equatable {
    let id: String
    let number: Int
    let nameTR: String
    let nameEN: String
    let meaningTR: String
    let meaningEN: String

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case nameTR = "tr"
        case nameEN = "en"
        case meaningTR = "meaningTr"
        case meaningEN = "meaningEn"
    }

    func name(language: String) -> String {
        language == "tr" ? nameTR : nameEN
    }

    func meaning(language: String) -> String {
        language == "tr" ? meaningTR : meaningEN
    }
}

// MARK: - Yükleyici + günlük seçim

/// Doğrulanmış içerik setleri: ayetler, hadisler, dualar, Esmaül Hüsna.
/// Önce RemoteContentService cache'ini dener; yoksa Bundle'daki gömülü JSON'a düşer.
/// Tamamen offline çalışır (cache yoksa gömülü JSON kullanılır).
enum DailyContent {
    @MainActor static let verses: [Verse] = load("ayetler")
    @MainActor static let hadiths: [Hadith] = load("hadisler")
    @MainActor static let duas: [Dua] = load("dualar")
    @MainActor static let esma: [EsmaName] = load("esma")

    /// Günün seed'i: yılın günü (1-366).
    private static func dayIndex(for date: Date) -> Int {
        Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    }

    @MainActor
    static func dailyVerse(for date: Date = Date()) -> Verse? {
        verses.isEmpty ? nil : verses[dayIndex(for: date) % verses.count]
    }

    @MainActor
    static func dailyHadith(for date: Date = Date()) -> Hadith? {
        hadiths.isEmpty ? nil : hadiths[dayIndex(for: date) % hadiths.count]
    }

    @MainActor
    static func dailyDua(for date: Date = Date()) -> Dua? {
        duas.isEmpty ? nil : duas[dayIndex(for: date) % duas.count]
    }

    @MainActor
    static func dailyEsma(for date: Date = Date()) -> EsmaName? {
        guard !esma.isEmpty else { return nil }
        let seed = dayIndex(for: date)
        let mixedIndex = (seed &* 37 &+ 17) % esma.count
        return esma[mixedIndex]
    }

    @MainActor
    private static func load<T: Decodable>(_ resource: String) -> [T] {
        let fileName = "\(resource).json"

        // 1. RemoteContentService cache'ini dene
        if let cached: [T] = RemoteContentService.shared.cachedContent(fileName) {
            return cached
        }

        // 2. Bundle fallback (ilk kurulumda her zaman çalışır)
        guard
            let url = Bundle.main.url(forResource: resource, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let items = try? JSONDecoder().decode([T].self, from: data)
        else {
            assertionFailure("İçerik dosyası okunamadı: \(resource).json")
            return []
        }
        return items
    }
}

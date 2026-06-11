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
/// Bundle'daki JSON dosyalarından okunur; tamamen offline, ağ gerektirmez.
/// Veri setleri büyütüldüğünde (50 ayet / 50 hadis / 40 dua) sadece JSON değişir.
enum DailyContent {
    static let verses: [Verse] = load("ayetler")
    static let hadiths: [Hadith] = load("hadisler")
    static let duas: [Dua] = load("dualar")
    static let esma: [EsmaName] = load("esma")

    /// Günün seed'i: yılın günü (1-366).
    private static func dayIndex(for date: Date) -> Int {
        Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    }

    static func dailyVerse(for date: Date = Date()) -> Verse? {
        verses.isEmpty ? nil : verses[dayIndex(for: date) % verses.count]
    }

    static func dailyHadith(for date: Date = Date()) -> Hadith? {
        hadiths.isEmpty ? nil : hadiths[dayIndex(for: date) % hadiths.count]
    }

    static func dailyDua(for date: Date = Date()) -> Dua? {
        duas.isEmpty ? nil : duas[dayIndex(for: date) % duas.count]
    }

    static func dailyEsma(for date: Date = Date()) -> EsmaName? {
        esma.isEmpty ? nil : esma[dayIndex(for: date) % esma.count]
    }

    private static func load<T: Decodable>(_ resource: String) -> [T] {
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

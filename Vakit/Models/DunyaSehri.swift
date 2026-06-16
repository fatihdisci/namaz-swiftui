import Foundation

/// Dünya şehri — dunya_sehirleri.json şeması.
struct DunyaSehri: Codable, Identifiable {
    var id: String { "\(ulke)-\(sehir)" }
    let ulke: String
    let sehir: String
    let lat: Double
    let lng: Double

    /// "Berlin, Almanya" formatında gösterim.
    var displayName: String { "\(sehir), \(ulke)" }

    /// Arama için normalize string: türkçe karakterleri düşür, küçük harf.
    var normalizedSearch: String {
        "\(ulke) \(sehir)"
            .lowercased()
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "\u{0069}\u{0307}", with: "i")
    }
}

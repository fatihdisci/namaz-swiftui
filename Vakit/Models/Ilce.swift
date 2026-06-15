import Foundation

/// Türkiye il/ilçe modeli — iller.json şeması.
struct Ilce: Codable, Identifiable {
    var id: String { "\(il)-\(ilce)" }
    let il: String       // "İzmir"
    let ilce: String     // "Konak"
    let lat: Double
    let lng: Double

    /// "Konak, İzmir" formatında gösterim.
    var displayName: String { "\(ilce), \(il)" }

    /// Arama için normalize string: türkçe karakterleri düşür, küçük harf.
    var normalizedSearch: String {
        let raw = "\(il) \(ilce)"
            .lowercased()
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ı", with: "i")
        // decomposed dotted i (İ/i̇) → plain i
        return raw
            .replacingOccurrences(of: "\u{0069}\u{0307}", with: "i")
    }

    enum CodingKeys: String, CodingKey {
        case il, ilce, lat, lng
    }
}

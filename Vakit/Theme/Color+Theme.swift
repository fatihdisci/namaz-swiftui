import SwiftUI

extension Color {
    // Arka plan
    static let vakitBg      = Color(hex: "0a0a0f")  // Ana arka plan
    static let vakitSurface = Color(hex: "13131a")  // Kart arka planı
    static let vakitBorder  = Color.white.opacity(0.08)

    // Vakit aksan renkleri
    static let fajr     = Color(hex: "7c3aed")  // Mor — Sabah/fecr
    static let sunrise  = Color(hex: "d97706")  // Amber — Güneş
    static let dhuhr    = Color(hex: "b45309")  // Altın — Öğle
    static let asr      = Color(hex: "c2410c")  // Bronz — İkindi
    static let maghrib  = Color(hex: "dc2626")  // Kırmızı — Akşam
    static let isha     = Color(hex: "1d4ed8")  // Lacivert — Yatsı

    // Metin
    static let vakitText    = Color(hex: "f1f0ed")
    static let vakitTextDim = Color(hex: "6b6a66")
    static let vakitAccent  = Color(hex: "7c3aed")  // Varsayılan mor
}

import SwiftUI

extension Color {
    // Arka plan
    static let vakitBg      = Color(hex: "080d0c")  // Ana arka plan
    static let vakitSurface = Color(hex: "111816")  // Kart arka planı
    static let vakitBorder  = Color.white.opacity(0.08)

    // Vakit aksan renkleri
    static let fajr     = Color(hex: "2dd4bf")  // Turkuaz — İmsak/fecr
    static let sunrise  = Color(hex: "d97706")  // Amber — Güneş
    static let dhuhr    = Color(hex: "ca8a04")  // Altın — Öğle
    static let asr      = Color(hex: "b45309")  // Bronz — İkindi
    static let maghrib  = Color(hex: "dc2626")  // Kırmızı — Akşam
    static let isha     = Color(hex: "2563eb")  // Lacivert — Yatsı

    // Metin
    static let vakitText    = Color(hex: "f1f0ed")
    static let vakitTextDim = Color(hex: "8a8f88")
    static let vakitAccent  = Color(hex: "2fbf8f")  // Varsayılan yeşil
}

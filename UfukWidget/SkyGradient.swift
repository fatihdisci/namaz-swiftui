import SwiftUI

// MARK: - Renk yardımcısı (widget target'a özel, app Theme'inden bağımsız)
//
// Bu palet bilinçli olarak ayrı tutulmuştur (widget rendering kısıtları: gradyan
// sistemi kendi içinde dengeli, her faz için 3 duraklı gradient). Ana uygulama
// paleti: Vakit/Theme/Color+Theme.swift (#080d0c tabanlı koyu yeşil-siyah).
// widget'ın mor tonlu gece paleti ile ana uygulamanın yeşil-siyah arka planı
// farklı yönlere gider — bu bilinçli bir tasarım tercihidir.
// Faz 9/10'da tam birleştirme değerlendirilebilir.

extension Color {
    /// 0xRRGGBB tam sayısından sRGB renk.
    init(rgbHex hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
}

// MARK: - Dinamik Gökyüzü Sistemi

/// Günün beş atmosferi. O anki vakte göre arka plan gradientini belirler.
enum SkyPhase {
    case fajr      // İmsak–Güneş: lacivert → şafak moru
    case morning   // Güneş–Öğle: lacivert mavi → açık mavi → altın ton
    case noon      // Öğle–İkindi: parlak mavi → beyaz-altın
    case afternoon // İkindi–Akşam: turuncu → mercan → mor (en zengin)
    case night     // Akşam–İmsak: derin mor → lacivert → siyah
}

extension SkyPhase {
    /// topLeading → bottomTrailing sıralı renk durakları.
    var stops: [Color] {
        switch self {
        case .fajr:
            return [Color(rgbHex: 0x1a1a3a), Color(rgbHex: 0x4a3a6a), Color(rgbHex: 0x8a5a7a)]
        case .morning:
            return [Color(rgbHex: 0x2a4a7a), Color(rgbHex: 0x5a8ab0), Color(rgbHex: 0xd0b070)]
        case .noon:
            return [Color(rgbHex: 0x3a6aa0), Color(rgbHex: 0x7aafd0), Color(rgbHex: 0xe8d8a8)]
        case .afternoon:
            return [Color(rgbHex: 0xd07a3a), Color(rgbHex: 0xc05a6a), Color(rgbHex: 0x6a3a7a)]
        case .night:
            return [Color(rgbHex: 0x2a1a4a), Color(rgbHex: 0x1a1a3a), Color(rgbHex: 0x0a0a1a)]
        }
    }

    /// Arka plan gradienti (topLeading → bottomTrailing).
    var gradient: LinearGradient {
        LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Daha açık (gündüz) fazlarda metnin okunması için hafif gölge gerekir.
    var needsTextShadow: Bool {
        switch self {
        case .morning, .noon: return true
        case .fajr, .afternoon, .night: return false
        }
    }
}

/// O anki vakte göre gökyüzü fazını hesaplar.
///
/// Faz sınırları:
/// - İmsak'tan önce → night (gece, şafak öncesi)
/// - İmsak–Güneş   → fajr
/// - Güneş–Öğle    → morning
/// - Öğle–İkindi   → noon
/// - İkindi–Akşam  → afternoon
/// - Akşam ve sonrası (Yatsı dâhil) → night
func currentSkyPhase(now: Date, snapshot: WidgetPrayerSnapshot) -> SkyPhase {
    func time(_ key: String) -> Date? {
        snapshot.rows.first { $0.prayerKey == key }?.time
    }
    guard
        let fajr = time("fajr"),
        let sunrise = time("sunrise"),
        let dhuhr = time("dhuhr"),
        let asr = time("asr"),
        let maghrib = time("maghrib")
    else {
        return .night
    }

    if now < fajr { return .night }
    if now < sunrise { return .fajr }
    if now < dhuhr { return .morning }
    if now < asr { return .noon }
    if now < maghrib { return .afternoon }
    return .night
}

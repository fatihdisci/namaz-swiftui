import SwiftUI

// MARK: - Vakit ikonları

/// Her namaz vakti için SF Symbol eşlemesi.
enum PrayerIcon {
    static func symbol(for prayerKey: String) -> String {
        switch prayerKey {
        case "fajr":    return "moon.stars.fill" // İmsak
        case "sunrise": return "sunrise.fill"    // Güneş
        case "dhuhr":   return "sun.max.fill"     // Öğle
        case "asr":     return "sun.min.fill"     // İkindi
        case "maghrib": return "sunset.fill"      // Akşam
        case "isha":    return "moon.fill"        // Yatsı
        default:        return "clock.fill"
        }
    }
}

/// Vakit ikonunu hierarchical render moduyla, altın/krem aksanla çizer.
struct PrayerIconView: View {
    let prayerKey: String
    var size: CGFloat = 18
    var color: Color = WidgetPalette.accentGold

    var body: some View {
        Image(systemName: PrayerIcon.symbol(for: prayerKey))
            .font(.system(size: size))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
    }
}

// MARK: - Widget renk paleti

/// Widget'a özel aksan ve metin renkleri. Tüm boyutlar bunu paylaşır.
enum WidgetPalette {
    /// Altın aksan (ikon + saat).
    static let accentGold = Color(rgbHex: 0xe8c878)
    static let accentGoldDeep = Color(rgbHex: 0xd0a850)
    /// Koyu gökyüzü üzerinde okunabilir krem metin.
    static let cream = Color(rgbHex: 0xf3efe3)
    static let creamDim = Color.white.opacity(0.72)
    static let creamFaint = Color.white.opacity(0.5)

    /// Progress halkası için altın gradient (#e8c878 → #d0a850).
    static var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [accentGold, accentGoldDeep, accentGold]),
            center: .center
        )
    }
}

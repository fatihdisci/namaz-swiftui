import SwiftUI

// MARK: - UI Tip Ölçeği (butonlar, başlıklar, etiketler)

extension Font {
    /// 56pt — App adı, onboarding hero
    static let vakitHero = Font.system(size: 56, weight: .bold, design: .rounded)

    /// 42pt — Büyük geri sayım (NextPrayerCard)
    static let vakitCountdown = Font.system(size: 42, weight: .bold, design: .rounded)

    /// largeTitle — Ekran başlığı (Settings, Discover)
    static let vakitScreenTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)

    /// title2 — Alt ekran başlığı (Qibla)
    static let vakitSectionTitle = Font.system(.title2, design: .rounded, weight: .semibold)

    /// headline — Kart başlığı, buton metni
    static let vakitHeadline = Font.system(.headline, design: .rounded, weight: .semibold)

    /// body (rounded) — Vakit saati, sayaç değeri
    static let vakitBodyRounded = Font.system(.body, design: .rounded, weight: .semibold)

    /// subheadline — Açıklama, alt bilgi
    static let vakitCaption = Font.subheadline
}

// MARK: - Okuma Tip Ölçeği (ayet, hadis, dua — Dynamic Type öncelikli)

extension Font {
    /// body — Uzun okuma metni (ayet/hadis çevirisi). Dynamic Type ile ölçeklenir.
    static let vakitBody = Font.system(.body, design: .default)

    /// Arapça metin — Dynamic Type ile ölçeklenir. En az 20pt.
    static var vakitArabic: Font {
        .system(.title3, design: .default, weight: .medium)
    }

    /// Atıf / kaynak satırı
    static let vakitReference = Font.caption

    /// Section başlığı (footer/group başlığı)
    static let vakitSectionHeader = Font.system(.footnote, design: .default, weight: .semibold)
}

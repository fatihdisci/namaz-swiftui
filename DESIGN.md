# VAKIT Design System

> **Status:** Codifying EXISTING identity. Not redesigning — standardizing for consistency across Phase 8 (Polish + App Store).
> **Source of truth:** `Vakit/Theme/Color+Theme.swift` is the authoritative color definition. This document describes what IS, not what should be.

---

## 1. Color System — Semantik Vakit Paleti

### 1.1 Background Tokens

```swift
// Color+Theme.swift — current values (as of 2026-06-24)
extension Color {
    static let vakitBg      = Color(hex: "080d0c")  // #080d0c — Ana arka plan (ultra-dark teal-black)
    static let vakitSurface = Color(hex: "111816")  // #111816 — Kart / yükseltilmiş yüzey
    static let vakitBorder  = Color.white.opacity(0.08) // #FFFFFF 8% — İnce ayrım çizgisi
}
```

**Kural:**
- `vakitBg` yalnızca tam ekran arka planda (ZStack root). Asla kart içlerinde kullanılmaz.
- `vakitSurface` her türlü kart, picker, liste satırı container'ında.
- `vakitBorder` tüm `.strokeBorder()` ve `Divider().overlay()` çağrılarında.
- `Color.vakitAccent.opacity(0.12)` vurgulu arka plan (aktif seçim, ikon çemberi).
- `Color.vakitAccent.opacity(0.25)` / `0.35` daha güçlü vurgu (aktif kart border).

### 1.2 Prayer Accent Colors

```swift
static let fajr     = Color(hex: "2dd4bf")  // Turkuaz — İmsak/fecr (serin, sabah)
static let sunrise  = Color(hex: "d97706")  // Amber  — Güneş (sıcak, yükseliş)
static let dhuhr    = Color(hex: "ca8a04")  // Altın  — Öğle (parlak, zirve)
static let maghrib  = Color(hex: "dc2626")  // Kırmızı — Akşam (sıcak, batış)
static let asr      = Color(hex: "b45309")  // Bronz  — İkindi (topraksı, olgunluk)
static let isha     = Color(hex: "2563eb")  // Lacivert — Yatsı (derin, gece)
```

**Semantik kullanım:**
| Token      | Nerede kullanılır                               |
|------------|-------------------------------------------------|
| `prayer.accentColor` | Vakit satırı ikonu, aktif/sıradaki vakit vurgusu |
| `prayer.accentColor.opacity(0.12)` | Aktif satır arka planı |
| `prayer.accentColor.opacity(0.25)` | NextPrayerCard gradient overlay |
| `prayer.accentColor.opacity(0.35)` | Aktif satır border |

### 1.3 Text Tokens

```swift
static let vakitText    = Color(hex: "f1f0ed")  // #f1f0ed — Birincil metin (sıcak beyaz)
static let vakitTextDim = Color(hex: "8a8f88")  // #8a8f88 — İkincil metin (yeşil-gri)
static let vakitAccent  = Color(hex: "2fbf8f")  // #2fbf8f — Varsayılan vurgu (yeşil)
```

**Kontrast denetimi (WCAG 2.1):**

| Kombinasyon              | Kontrast | WCAG AA (4.5:1) | WCAG AAA (7:1) |
|--------------------------|----------|-----------------|----------------|
| vakitText on vakitBg     | ~17.2:1  | ✅              | ✅             |
| vakitTextDim on vakitBg  | ~5.9:1   | ✅              | ❌ (borderline)|
| vakitAccent on vakitBg   | ~6.5:1   | ✅              | ❌             |
| vakitAccent on vakitSurface | ~5.8:1 | ✅              | ❌             |

> **Not:** `vakitTextDim` WCAG AAA'nın hemen altında. Hadis/ayet uzun okumaları için `vakitText` kullanılması şart. `vakitTextDim` yalnızca yardımcı etiketlerde (referans, altbaşlık, caption) — bu zaten mevcut kodda böyle uygulanıyor.

**Geçmiş vakit karartma:**
- `PrayerListRow`: geçmiş vakit `opacity(0.4)` → efektif kontrast yaklaşık 7:1'e düşer, AA'yı hâlâ geçer.
- Bu bilinçli bir tasarım kararıdır — geçmiş/gelecek ayrımı semantik renk üzerinden verilir.

### 1.4 Renk Kullanım Denetim Sonucu

**✅ Mükemmel tutarlılık.** Tüm ekranlar yukarıdaki semantik token'ları kullanıyor. Tek hardcoded renk istisnası: `ShareableContentView.swift` — paylaşım görseli üretimi için kendi dark/light paletini tanımlar (export edilen PNG arka planı). Bu bilinçli ve doğru.

**Hata rengi:** `Color.maghrib` (kırmızı) hata/uyarı metinlerinde kullanılmış — uygun. Ancak anlamsal olarak `Color.error` adında ayrı bir token daha iyi olurdu.

---

## 2. Typography System

### 2.1 Mevcut Durum

Repoda merkezi bir `Font+Theme.swift` yok. Tüm font tanımları view içlerinde `.font(.system(...))` ile serpiştirilmiş. Buna rağmen **oldukça tutarlı bir pattern** var:

**Mevcut tip ölçeği (fiili kullanım analizi):**

| Rol                     | Mevcut              | Tasarım          | Weight    |
|-------------------------|---------------------|-------------------|-----------|
| App adı (onboarding)    | size: 56            | .rounded           | .bold     |
| Büyük geri sayım        | size: 42, 52        | .rounded           | .bold     |
| Ekran başlığı           | .largeTitle         | .rounded           | .bold     |
| Kart başlığı / Bölüm    | .headline           | .rounded           | .semibold |
| Vakit adı (liste)       | .body               | .default           | .medium / .semibold |
| Vakit saati (liste)     | .body               | .rounded           | .semibold |
| Buton metni             | .headline / .body   | .rounded           | .semibold |
| Uzun içerik (ayet/hadis)| .body               | .default           | .regular  |
| Arapça metin            | size: 20, 22        | .default           | .medium   |
| Açıklama / alt metin    | .subheadline / .caption | .default       | .regular  |
| İkon (SF Symbol)        | size: 10-22 arası   | .default           | .medium-.bold |
| Section başlığı         | .footnote           | .default           | .semibold, .textCase(.uppercase) |

### 2.2 Denetim Bulguları

**✅ İyi:**
- SF Pro `.rounded` ve `.default` tasarım ayrımı bilinçli: sayılar/butonlar/sayaçlar → `.rounded`, okuma metni → `.default`. Bu korunmalı.
- Geri sayım `.minimumScaleFactor(0.6)` ile Dynamic Type kısmen destekleniyor.
- `WelcomeStepView` 56pt app adı → onboarding'de marka etkisi. Doğru.

**❌ Eksik / Risk:**
- **Arapça metin sabit punto (20-22pt). Dynamic Type desteklemiyor.** Ayet okuması için kritik — yaşlı/görme zayıf kullanıcılar.
- **Hadis/ayet gövde metni `.body` kullanıyor** → Dynamic Type ile ölçeklenir (iyi), ama `vakitTextDim` ile yazılmış referans/atıf satırları `.caption` boyutunda — uzun okumada sorun değil.
- **`lineSpacing(4-5)`** ayet/hadis kartlarında elle ayarlanmış → Dynamic Type büyüdüğünde bu sabit değer orantısız kalabilir. `relativeTo` tabanlı spacing daha iyi olur.

### 2.3 Önerilen Tipografi Sistemi (Yeni `Font+Theme.swift`)

Amaç: Mevcut pattern'leri bozmadan, onları bir scale'de standartlaştırmak.

```swift
// Font+Theme.swift — tip ölçeği (yeni dosya önerisi)
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
        // body boyutundan yukarı, en az 20pt aşağıda kalmaz
        .system(.title3, design: .default, weight: .medium)
    }

    /// Atıf / kaynak satırı
    static let vakitReference = Font.caption

    /// Section başlığı (footer/group başlığı)
    static let vakitSectionHeader = Font.system(.footnote, design: .default, weight: .semibold)
}
```

**Tip ölçeği pt tablosu (referans):**

| Token               | iOS text style | approx pt | Weight   | Design  | Dynamic Type |
|---------------------|---------------|-----------|----------|---------|-------------|
| `.vakitHero`        | — (custom 56) | 56        | bold     | rounded | ❌ (sabit)  |
| `.vakitCountdown`   | — (custom 42) | 42        | bold     | rounded | ❌ (minScale ile) |
| `.vakitScreenTitle` | .largeTitle   | 34        | bold     | rounded | ✅          |
| `.vakitSectionTitle`| .title2       | 22        | semibold | rounded | ✅          |
| `.vakitHeadline`    | .headline     | 17        | semibold | rounded | ✅          |
| `.vakitBodyRounded` | .body         | 17        | semibold | rounded | ✅          |
| `.vakitBody`        | .body         | 17        | regular  | default | ✅          |
| `.vakitArabic`      | .title3       | 20        | medium   | default | ✅          |
| `.vakitCaption`     | .subheadline  | 15        | regular  | default | ✅          |
| `.vakitReference`   | .caption      | 12        | regular  | default | ✅          |
| `.vakitSectionHeader`| .footnote    | 13        | semibold | default | ✅          |

> **Not:** Hero (56pt) ve Countdown (42pt) fixed-size olarak kalır, ancak Countdown `.minimumScaleFactor(0.6)` ile taşmayı önler. Hero onboarding'de bir kerelik görünür — Dynamic Type'a ihtiyacı yok.

---

## 3. Spacing System — 4pt Grid

### 3.1 Mevcut Durum

8pt grid YOK. Mevcut padding değerleri: 4, 8, 10, 12, 14, 16, 18, 20, 24, 32.

**En sık kullanılanlar:** 12, 16, 20, 24, 32. Bunlar 4'ün katı → **doğal bir 4pt soft-grid var.**

**4pt grid'e UYMAYAN değerler:**
- `10` (HomeView topBar padding, SettingsView.horizontal, DiscoverView spacing, WidgetStep spacing)
- `14` (çoğu pickerRow, admin list, cityResult, autoLocateButton, WhatsNewRow)
- `18` (DuaLibraryView, AsrInfoSheet, PrayerCalendarView)

Bu değerler 4pt'ye yuvarlandığında:
- 10 → 8 ya da 12 (tasarımcı kararı)
- 14 → 12 ya da 16
- 18 → 16 ya da 20

### 3.2 Önerilen Spacing Kuralı

Mevcut değerlere en yakın 4pt grid adımları:

```
4pt  — En dar boşluk: ikon-metin arası, badge padding
8pt  — Dar boşluk: HStack eleman arası, card title-content
12pt — Standart boşluk: vakit listesi satır arası, ikon-metin
16pt — Geniş boşluk: kart padding, kart arası dikey boşluk
20pt — Bölüm arası boşluk: HomeView VStack spacing
24pt — Section arası geniş boşluk: Settings, Discover
32pt — Sayfa kenar boşluğu: onboarding yatay padding
```

**Kural:** Tüm yeni `.padding(_:)` ve `spacing:` değerleri 4'ün katı olmalı. Mevcut 10/14/18 istisnaları Phase 8'de en yakın 4pt değere normalize edilebilir (12/16/20).

### 3.3 Layout Token'ları (Önerilen Spacing+Theme.swift)

```swift
// Spacing+Theme.swift — boşluk sistemi (yeni dosya önerisi)
import CoreGraphics

extension CGFloat {
    /// 4pt — en dar: ikon-metin arası, badge
    static let vakitSpaceXS: CGFloat = 4
    /// 8pt — dar: HStack eleman arası, title-content vertical
    static let vakitSpaceSM: CGFloat = 8
    /// 12pt — standart: row arası, ikon container
    static let vakitSpaceMD: CGFloat = 12
    /// 16pt — geniş: kart padding, kart arası
    static let vakitSpaceLG: CGFloat = 16
    /// 20pt — bölüm arası: ana VStack spacing
    static let vakitSpaceXL: CGFloat = 20
    /// 24pt — section arası: Settings/Discover VStack
    static let vakitSpace2XL: CGFloat = 24
    /// 32pt — sayfa kenar: onboarding yatay padding
    static let vakitSpace3XL: CGFloat = 32
}
```

---

## 4. Dark Background Readability — Kontrast Kuralları

### 4.1 Minimum Kontrast Değerleri

| İçerik türü          | Min kontrast | Token kuralı                                |
|----------------------|-------------|----------------------------------------------|
| Uzun okuma (ayet/hadis) | 7:1 (AAA)   | `vakitText` on `vakitBg`/`vakitSurface`     |
| Kısa metin (UI label)   | 4.5:1 (AA)  | `vakitText` on `vakitBg`/`vakitSurface`     |
| Yardımcı metin (caption)| 4.5:1 (AA)  | `vakitTextDim` on `vakitBg`/`vakitSurface`  |
| Devre dışı (past prayer) | ~3:1 (izin verilir) | Geçmiş vakit opacity 0.4 — semantik karartma |
| Arapça metin          | 7:1 (AAA)   | `vakitText` on `vakitBg` — 17:1 ✅          |

### 4.2 Mevcut Denetim Sonucu

- ✅ `vakitText` on `vakitBg`: ~17.2:1 — WCAG AAA'nın 2.5 katı.
- ✅ `vakitTextDim` on `vakitBg`: ~5.9:1 — AA'yı geçiyor, AAA sınırda.
- ✅ Arapça metinler `vakitText` ile → AAA.
- ✅ Uzun meal metinleri `vakitText` ile → AAA.
- ⚠️ `vakitAccent` (#2fbf8f) koyu zeminde ~6.5:1 — AA'yı geçiyor, AAA'nın altında. Küçük ikon/butonlarda sorun değil. Uzun metinde asla kullanılmamalı.
- ✅ Geçmiş vakit `opacity(0.4)` bilinçli bir semantik sinyal.

### 4.3 Kontrast Kuralı (Yeni Kod İçin)

```
- Tüm kullanıcıya dönük metin 'vakitText' veya 'vakitTextDim' ile renklendirilir.
- Uzun okuma (≥2 satır) ASLA 'vakitTextDim' ile yazılmaz.
- 'vakitAccent' yalnızca ikon, buton metni, badge, section başlığında.
  Asla gövde metninde kullanılmaz.
- Yeni bir semantik renk eklenirse kontrastı vakitBg üzerinde hesaplanıp
  bu dosyaya belgelenir.
```

---

## 5. Notification Text Psychology

### 5.1 Mevcut Durum

```swift
// Şu anki bildirim metni (NotificationService.swift:120-122):
content.body = setting.minutesBefore > 0
    ? "%@ vaktine %ld dakika kaldı."  // Sabah vaktine 15 dakika kaldı.
    : "%@ vakti başladı."              // Sabah vakti başladı.
```

**Analiz:** İşlevsel, doğru, ama "robotik." Namaz bir ibadet — bildirim, kullanıcıyı motive eden, bağlamsal bir mikro-metin olabilir. Apple HIG notification guidelines: "bildirimler kişisel, kısa ve harekete geçirici olmalı."

### 5.2 Önerilen Bildirim Metni Standardı

İki katman:

**Katman 1 — Standart (şu anki gibi, her zaman gösterilir):**
```
"Sabah vakti başladı."
"Öğle vaktine 15 dakika kaldı."
```

**Katman 2 — Motive edici alt metin (opsiyonel, kullanıcı ayarıyla açılır):**
```
"Sabah namazı güne huzurla başlamandır."
"Öğle vakti yaklaşıyor, hazır mısın?"
"Akşam güneşle birlikte şükür vakti."
"Yatsı namazı geceni aydınlatsın."
```

**Kurallar:**
1. Bildirim başlığı her zaman vakit adıdır (şu anki gibi).
2. Gövde metni `notification.body.started` / `notification.body.remaining` string kataloğundan.
3. Motive edici varyantlar ayrı bir `notification.notes` ayarı altında, her vakit için opsiyonel.
4. Metin uzunluğu notification center'da 2 satırı geçmemeli (yaklaşık 60-80 karakter).
5. Emoji/emoji-olmayan tutarlı: Türkçe'de emoji kullanılmaz (kültürel tercih).

---

## 6. Motion — Aurora & ReduceMotion

### 6.1 Mevcut Durum

```swift
// AuroraBackground.swift
.animation(.easeInOut(duration: 1.5), value: accentColor)
```

- ✅ Yumuşak 1.5s geçiş — Aurora hissi mükemmel.
- ❌ `@Environment(\.accessibilityReduceMotion)` KONTROLÜ YOK.
- ❌ Repoda başka hiçbir yerde reduceMotion kontrolü yok.

### 6.2 Önerilen Motion Kuralları

```swift
// AuroraBackground — reduceMotion uyumlu hali
struct AuroraBackground: View {
    let accentColor: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            // ... mevcut ZStack aynen ...
        }
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 1.5),
            value: accentColor
        )
        .ignoresSafeArea()
    }
}
```

**Tüm motion kullanımları için kurallar:**
1. Aurora geçişi: reduceMotion açıksa `.none`, kapalıysa `.easeInOut(1.5)`.
2. Onboarding geçişi (`OnboardingView`): `.easeInOut(0.35)` — reduceMotion'da `.none`.
3. `contentTransition(.numericText())` (geri sayım, kaza sayacı) — reduceMotion'da kapatılmaz; bu bir hareket/animation değil, statik metin değişimi.
4. ScrollView doğal scroll'u reduceMotion'dan etkilenmez (doğru).
5. Yeni eklenen her `.animation()` ve `withAnimation` reduceMotion kontrolüyle sarılmalı.

### 6.3 Motion Token'ları (Önerilen)

```swift
// Motion+Theme.swift — motion süreleri (yeni dosya önerisi)
extension Animation {
    /// Aurora renk geçişi, büyük layout değişiklikleri
    static let vakitSlow = Animation.easeInOut(duration: 1.5)
    /// Onboarding step geçişi, sheet present
    static let vakitMedium = Animation.easeInOut(duration: 0.35)
    /// Mikro etkileşim: buton hover, selection
    static let vakitFast = Animation.easeInOut(duration: 0.2)
}

// Helper
func vakitAnimation(_ animation: Animation, reduceMotion: Bool) -> Animation {
    reduceMotion ? .none : animation
}
```

---

## 7. Component Tokens — Corner Radius & Shadow

### 7.1 Mevcut Corner Radius Pattern'leri

| Bileşen                | cornerRadius | Style        |
|------------------------|-------------|--------------|
| Büyük kart (NextPrayer)| 20          | .continuous  |
| Standart kart          | 16-18       | .continuous  |
| Küçük eleman (badge)   | 8-9         | .continuous  |
| Satır (list row)       | 14          | .continuous  |
| Buton (primary CTA)    | 14-16       | .continuous  |
| Pill / Capsule         | Capsule()   | —            |
| İkon çemberi           | Circle()    | —            |
| Top bar                | 22          | .continuous  |

**Pattern:** Dış container → 16-20pt radius. İç eleman → 14pt. Badge/ikon grubu → 8-12pt. Hepsi `.continuous`.

### 7.2 Shadow

```swift
// Şu anki kullanım (HomeView topBar):
.shadow(color: Color.black.opacity(0.12), radius: 18, y: 10)
```

Shadow yalnızca topBar'da var. Kartlar shadow kullanmıyor — border ile ayrılıyor. Bu bilinçli: karanlık zeminde shadow görünmez, border daha iyi çalışır.

**Kural:** Karanlık zeminde gölge KULLANMA. Border yeterli. Açık zeminde (paylaşım görseli gibi) gölge iyidir.

---

## 8. Dead File — Cleanup

`Vakit/Theme/Untitled.swift`: 8 satır, boş dosya. Yalnızca Xcode'un otomatik oluşturduğu header yorumu var. Hiçbir kod yok.

**Aksiyon:** Silinmeli.

---

## 9. CONSTITUTION.md Renk Sapması

CONSTITUTION.md'deki renk değerleri ile `Color+Theme.swift`'teki gerçek kod farklı. CONSTITUTION.md güncel değil.

| Token        | CONSTITUTION.md | Color+Theme.swift (gerçek) |
|--------------|----------------|---------------------------|
| vakitBg      | #0a0a0f        | #080d0c                   |
| vakitSurface | #13131a        | #111816                   |
| fajr         | #7c3aed (mor)  | #2dd4bf (turkuaz)         |
| dhuhr        | #b45309        | #ca8a04                   |
| asr          | #c2410c        | #b45309                   |
| isha         | #1d4ed8        | #2563eb                   |
| vakitTextDim | #6b6a66        | #8a8f88 (daha açık, daha erişilebilir) |
| vakitAccent  | #7c3aed (mor)  | #2fbf8f (yeşil)           |

**Aksiyon:** CONSTITUTION.md Phase 8'de güncellenmeli. Renklerin kaynağı `Color+Theme.swift`'tir.

---

## 10. Open Question — Font Direction

Mevcut sistem `Font.system(. ..., design: .rounded)` ve `.system(. ..., design: .default)` kullanıyor — tamamen SF Pro ailesi. Bu sadelik CONSTITUTION.md'nin "sistem fontu kullan, custom font yükleme YOK" kuralıyla uyumlu.

Ancak ayet/hadis gibi uzun okuma içerikleri için:

**Seçenek A — SF Pro (mevcut):**
- ✅ Sıfır ek yük, app bundle'a font eklenmez
- ✅ iOS ile gelen Dynamic Type, kerning, leading optimizasyonları
- ✅ CONSTITUTION.md ile uyumlu
- ❌ Uzun okumada "UI fontu" hissi verebilir

**Seçenek B — SF Pro + özel okuma fontu (sadece ayet/hadis/dua için):**
- Örneğin: `Georgia` (serif, iOS built-in), `Palatino`, ya da açık kaynak bir Arapça+Latin font (Amiri, Scheherazade New)
- ✅ Okuma deneyimi daha sıcak, "kitap hissi"
- ✅ Arapça metin için native rendering
- ❌ Ek yük (font dosyası), bakım, Arapça-Latin font pairing karmaşası
- ❌ CONSTITUTION.md ihlali (custom font YOK kuralı)

**Seçenek C — SF Pro Rounded (default-rounded ayrımını kaldır, hep rounded):**
- ✅ UI bütünlüğü
- ❌ Uzun okuma metninde rounded sans-serif yorucu olabilir

**Öneri:** Seçenek A (mevcut SF Pro, CONSTITUTION uyumlu). Phase 8'de kullanıcı testiyle okunabilirlik feedback'i alınabilir. Eğer ileride custom font eklenirse sadece Arapça metin (`.vakitArabic`) için olmalı.

---

*DESIGN.md v1.0 — 2026-06-24. Vakit Phase 8 Polish audit.*

# VAKIT — SwiftUI Anayasası (CONSTITUTION.md)

> Bu dosyayı her oturumun başında oku. Tüm mimari kararlar, tasarım sistemi ve kurallar burada. Hiçbir karar bu dosyayla çelişemez.

-----

## Proje Özeti

**Vakit** — iOS-only namaz vakitleri uygulaması, **SwiftUI ile native**.
Bu proje daha önce Expo/React Native ile yazıldı (`github.com/fatihdisci/namaz`). Şimdi **sıfırdan SwiftUI’a** taşınıyor. Tüm işlevler, tasarım ve renkler birebir korunacak; sadece teknoloji native iOS oluyor.

-----

## Repo Stratejisi (ÇOK ÖNEMLİ)

İki ayrı repo var:

- **Referans repo (SADECE OKU, ASLA DEĞİŞTİRME):** `github.com/fatihdisci/namaz`
  Eski Expo/React Native sürümü. Agent buradaki kodu işlev ve veri akışı doğrulaması için **inceleyebilir** ama **asla commit/push atmaz**, üstünde çalışmaz.
- **Çalışma repo’su (BURAYA YAZ):** `github.com/fatihdisci/namaz-swiftui`
  Tüm yeni SwiftUI kodu buraya. Tüm commit ve push’lar SADECE bu repoya gider.

**Kurallar:**

1. Referans repoyu sadece okumak için ayrı bir `/reference` klasörüne clone’la ya da GitHub üzerinden incele. Üstüne hiçbir şey yazma.
1. Yeni SwiftUI projesi çalışma repo’sunda yaşar. Her commit öncesi `git remote -v` ile origin’in çalışma repo’su olduğunu doğrula.
1. Yanlışlıkla `namaz` repo’suna push atma — çalışma dizininin doğru repo olduğunu kontrol et.
1. Her faz sonunda çalışma repo’suna commit + push at.

**Killer feature:** “Seferi miyim?” — hiçbir rakipte yok.
**Hedef:** Türkiye önce, sonra global Müslüman kitlesi.
**Model:** Freemium — RevenueCat ile Pro.
**Platform:** Sadece iOS 17+. Android YOK, hiç düşünme.

-----

## Neden SwiftUI (Expo’dan farkı)

Expo’da widget, Dynamic Island, Apple Watch için config plugin yazıp signing/target savaşı verildi. SwiftUI’da bunlar **native ve birinci sınıf**:

- Widget → WidgetKit (ayrı target, sorunsuz)
- Dynamic Island → ActivityKit
- Apple Watch → watchOS target
- Build → Mac mini’de yerel, EAS kotası YOK

-----

## Teknoloji Stack

```
SwiftUI (iOS 17.0+ minimum deployment)
Swift 5.9+
Xcode 16+

Veri & Persistans:
- SwiftData (kaza takibi, çoklu şehir, ayarlar gibi yapısal veri)
- UserDefaults + App Group (widget ile paylaşılan basit veri)
- @AppStorage (basit tekil ayarlar)

Namaz Vakti:
- Adhan (Swift) — https://github.com/batoulapps/adhan-swift — SPM ile
  (Expo'daki adhan-js'in resmi Swift karşılığı, AYNI hesaplama)
- Aladhan REST API — online kaynak + cache

Sistem Framework'leri:
- CoreLocation (konum + pusula heading)
- UserNotifications (bildirimler)
- WidgetKit (widget)
- ActivityKit (Dynamic Island / Live Activity)
- WatchConnectivity + watchOS target (Apple Watch)

Üçüncü Parti (SPM):
- RevenueCat (Pro satın alma) — https://github.com/RevenueCat/purchases-ios

Lokalizasyon:
- String Catalog (.xcstrings) — TR + EN
```

**Paket yönetimi:** Sadece Swift Package Manager (SPM). CocoaPods YOK.

-----

## API — Aladhan

**Endpoint:** `GET https://api.aladhan.com/v1/timings/{DD-MM-YYYY}`

**Parametreler:**

- `latitude`, `longitude` (Double)
- `method` (Int): **13 = Diyanet** (Türkiye varsayılan), 3 = MWL, 2 = ISNA, 4 = Umm al-Qura, 5 = Egyptian
- `school` (Int): **0 = Standart** (varsayılan), 1 = Hanefi (kullanıcı seçimi, ikindi için)

**Key yok, rate limit yok, bedava.**

**Offline strateji (kritik):**

1. İnternet varsa Aladhan’dan çek → UserDefaults/SwiftData’ya 30 günlük cache
1. İnternet yoksa **Adhan Swift** ile lokal hesapla (`CalculationMethod.turkey`)
1. Kullanıcı farkı hissetmez, sessiz geçiş
1. Namaz vakti uygulaması ASLA internet bağımlısı olamaz

-----

## Tasarım Sistemi — Aurora Koyu Tema (DEĞİŞMEZ)

Sabit koyu tema. Renk aksanı aktif vakte göre değişir.

```swift
// Color+Theme.swift — bu renkler birebir korunacak
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
```

`Color(hex:)` init helper’ı yazılacak (UIColor üzerinden hex parse).

**Tema kuralları:**

- Arka plan her zaman koyu (`vakitBg`), light mode YOK
- Aktif/sonraki vakit kartı o vaktin aksan rengini kullanır
- Geçmiş vakitler `opacity(0.4)` ile soluk
- Aurora hissi: koyu zemin üzerinde yumuşak radial gradient ışık lekeleri (aktif vaktin renginde), `.blur()` ile

**Tipografi:**

- Büyük geri sayım: SF Pro Rounded, bold, büyük punto
- Vakit isimleri: SF Pro, medium
- Sistem fontu kullan, custom font yükleme YOK (sadelik)

-----

## Klasör / Dosya Yapısı

```
Vakit/                          # Ana app target
  VakitApp.swift                # @main App entry
  ContentView.swift             # Root TabView

  Models/
    Prayer.swift                # enum: fajr, sunrise, dhuhr, asr, maghrib, isha
    PrayerTimes.swift           # bir günün vakitleri + hicri tarih
    City.swift                  # şehir modeli (SwiftData)
    KazaEntry.swift             # kaza kaydı (SwiftData)
    CalculationMethod.swift     # Aladhan metod enum'u

  Services/
    PrayerTimeService.swift     # Aladhan + Adhan Swift + cache
    NotificationService.swift   # UserNotifications
    LocationService.swift       # CoreLocation (tek seferlik + heading)
    QiblaService.swift          # Kabe açısı + pusula
    SafarService.swift          # Seferi mesafe hesabı (Haversine)
    StorageService.swift        # UserDefaults / App Group wrapper
    PurchaseService.swift       # RevenueCat izolasyonu

  ViewModels/
    HomeViewModel.swift
    QiblaViewModel.swift
    SettingsViewModel.swift
    ...

  Views/
    Home/
      HomeView.swift
      NextPrayerCard.swift
      PrayerListRow.swift
      DailyContentCard.swift
      AuroraBackground.swift
    Qibla/
      QiblaView.swift
      CompassView.swift
    Settings/
      SettingsView.swift
      NotificationSettingsView.swift
      SafarView.swift           # Pro
      KazaView.swift            # Pro
      CitiesView.swift          # Pro
      PaywallView.swift
    Onboarding/
      OnboardingView.swift
      CitySelectionView.swift
      MethodSelectionView.swift
      NotificationPermissionView.swift
    Components/
      ProGateView.swift         # Pro kilidi modal
      DevProToggle.swift        # SADECE #if DEBUG

  Resources/
    Localizable.xcstrings       # TR + EN String Catalog
    DailyContent.swift          # 30+ ayet/hadis (TR+EN), offline

  Theme/
    Color+Theme.swift
    Color+Hex.swift

VakitWidget/                    # Widget extension target
  VakitWidgetBundle.swift       # @main (ayrı target, çakışma yok)
  PrayerWidget.swift
  PrayerWidgetView.swift
  PrayerTimelineProvider.swift

VakitWatch/                     # watchOS target (Phase 7)
  ...

Shared/                         # App + Widget + Watch ortak kod
  SharedModels/
  AppGroup.swift                # group.com.fatihdisci.vakit.shared
```

**App Group:** `group.com.fatihdisci.vakit.shared` (Expo’dan aynı, widget veri paylaşımı için)
**Bundle ID:** `com.vakit.app` (ana), `com.vakit.app.widget` (widget)

-----

## Free vs Pro

|Özellik                               |Free|Pro|
|--------------------------------------|----|---|
|Namaz vakitleri + geri sayım          |✅   |✅  |
|Bildirimler (vakit bazlı özelleştirme)|✅   |✅  |
|Kıble yönü                            |✅   |✅  |
|Günlük ayet/hadis                     |✅   |✅  |
|Tek şehir                             |✅   |✅  |
|**Seferi hesabı**                     |❌   |✅  |
|**Kaza takibi**                       |❌   |✅  |
|**Çoklu şehir (max 5)**               |❌   |✅  |
|**Widget**                            |❌   |✅  |
|**Dynamic Island / Live Activity**    |❌   |✅  |
|**Apple Watch**                       |❌   |✅  |

**Pro gating:** `PurchaseService.isPro` üzerinden. Pro olmayan bir özelliğe dokununca `ProGateView` (paywall) gösterilir.

**RevenueCat ürünleri:**

```
com.vakit.pro.monthly   → Aylık
com.vakit.pro.yearly    → Yıllık
com.vakit.pro.lifetime  → Tek seferlik
Entitlement: "pro"
```

-----

## Kritik Kurallar (ASLA İHLAL ETME)

1. **Konum asla kalıcı saklanmaz.** Seferi ve kıble için `CLLocationManager` ile tek seferlik konum alınır, işlem bitince referans bırakılmaz. Kullanıcıya “konumunuz saklanmaz” notu gösterilir.
1. **Offline her zaman çalışır.** Her ağ çağrısı `do/catch` ile sarılır; hata → Adhan Swift lokal hesaplama devreye girer.
1. **Her vakit bildirimi bağımsız.** Kullanıcı Sabah’ı kapatınca diğerleri etkilenmez. Her vakit ayrı notification identifier.
1. **RevenueCat izole.** RevenueCat’e dair tüm kod `PurchaseService.swift` içinde. Başka hiçbir dosya doğrudan RevenueCat API’si çağırmaz.
1. **Lokalizasyon zorunlu.** Hardcoded string YOK. Tüm kullanıcıya görünen metin String Catalog (`Localizable.xcstrings`) üzerinden. Kod/değişken isimleri İngilizce.
1. **App Group tutarlılığı.** Widget ve ana app `group.com.fatihdisci.vakit.shared` üzerinden veri paylaşır. UserDefaults suite adı bu grupla aynı olmalı.
1. **Widget/Watch ayrı target.** Her birinin kendi `@main`‘i kendi target’ında. Ortak kod `Shared/` klasöründe, ilgili target’lara membership ile eklenir.
1. **MVVM.** View → ViewModel → Service katmanı. View içinde doğrudan ağ/hesaplama YOK. `@Observable` (iOS 17 Observation framework) kullan, eski `ObservableObject` yerine.
1. **Tasarım renkleri değişmez.** Yukarıdaki hex kodları sabit. Yeni renk ekleme, var olanı değiştirme.

-----

## Vakit İsimleri (Lokalizasyon)

|key    |TR    |EN     |
|-------|------|-------|
|fajr   |Sabah |Fajr   |
|sunrise|Güneş |Sunrise|
|dhuhr  |Öğle  |Dhuhr  |
|asr    |İkindi|Asr    |
|maghrib|Akşam |Maghrib|
|isha   |Yatsı |Isha   |

İlk açılışta cihaz dili Türkçe → TR, diğer → EN. Ayarlardan değiştirilebilir.

-----

## Faz Haritası

|Faz    |Kapsam                                                       |
|-------|-------------------------------------------------------------|
|Phase 0|Xcode projesi + paketler + tema/renk sistemi                 |
|Phase 1|Veri katmanı + PrayerTimeService (Aladhan + Adhan + cache)   |
|Phase 2|Ana ekran UI (Aurora, geri sayım, liste, ayet/hadis)         |
|Phase 3|Onboarding + Lokalizasyon                                    |
|Phase 4|Bildirimler + Kıble                                          |
|Phase 5|Pro özellikler (Seferi + Kaza + Çoklu şehir) + DEV Pro toggle|
|Phase 6|RevenueCat + Pro gating                                      |
|Phase 7|Widget + Dynamic Island + Apple Watch                        |
|Phase 8|Polish + App Store hazırlık                                  |

Detaylı promptlar `VAKIT-SWIFTUI-PROMPT-KIT.md` dosyasında.

-----

## Agent Çalışma Protokolü

1. Her faz başında bu anayasayı oku.
1. Verilen fazın promptundaki görevleri sırayla yap.
1. Her faz sonunda projenin Xcode’da **derlendiğini** doğrula (`xcodebuild` veya Xcode build).
1. Faz bitince `git commit` at: `"Phase X: <özet>"`.
1. Bir sonraki faza ancak mevcut faz derlenip çalışınca geç.
1. Mevcut Expo repo’sunu (`github.com/fatihdisci/namaz`) referans olarak incele — işlev ve veri akışını oradan doğrula, ama kodu Swift idiyomatik şekilde yeniden yaz (satır satır çeviri DEĞİL).

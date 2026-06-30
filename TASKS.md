# Vakit SwiftUI — Görev Takip

> Proje: Ufuk — Namaz Vakitleri (iOS 17+)
> Ana dosya: [VAKIT-SWIFTUI-CONSTITUTION.md](VAKIT-SWIFTUI-CONSTITUTION.md)

---

## Tamamlanan Fazlar

| Faz | Açıklama | Durum |
|-----|----------|-------|
| Phase 0 | Xcode projesi + paketler + tema/renk sistemi | ✅ |
| Phase 1 | Veri katmanı + PrayerTimeService (Aladhan + Adhan + cache) | ✅ |
| Phase 2 | Ana ekran UI (Aurora, geri sayım, liste, ayet/hadis) | ✅ |
| Phase 3 | Onboarding + Lokalizasyon (TR/EN) | ✅ |
| Phase 4 | Bildirimler + Kıble | ✅ |
| Phase 5 | Pro özellikler (Seferi + çoklu şehir limiti) + free kaza takibi + DEV Pro toggle | ✅ |
| Phase 6 | RevenueCat + Pro gating | ✅ |
| Phase 7 | Temel widget | ✅ |
| Phase 8 | Polish + App Store hazırlık | ✅ |

---

## Son Yapılanlar

- **Konum seçimi yeniden tasarım**: Zorunlu konum izni kaldırıldı, cascading seçim (Ülke → İl → İlçe) eklendi, Türkiye için local JSON datası
- **ShareableContentView**: Discover içerikleri için paylaşılabilir görsel üretimi (Story/Kare format, ImageRenderer)
- **Konum servis düzeltmeleri**: CLLocationManager delegate + MainActor garantisi
- **DEBUG Pro**: `hasProAccess` her zaman true, Settings'te paywall önizleme
- **Asr/Diyanet doğrulaması**: Diyanet tablosu ve Aladhan `method=13` çıktısı Standard Asr (`school=0`) ile eşleşiyor; Diyanet için Hanefi otomatik seçim geri alındı. **Correction migration**: Hatalı eski göçle Diyanet + Hanefi'ye taşınmış kullanıcılar (`school=1`, `hasManuallySetAsrCalculation=false`) bir kerelik Standart'a (0) döndürülüyor (`StorageService.correctErroneousAsrSchoolIfNeeded()`, `asrSchoolStandardCorrectionMigrated` flag ile). Manuel seçim ezilmiyor.
- **1.3.0 Free/Pro sadeleşmesi**: Kıble, KazaView ve temel widget free; Free şehir limiti 2 kayıtlı şehir, Pro şehir limiti 10; ProGate metinleri seferi hesabı ve çoklu şehir limitine odaklandı.

---

## Mimari

```
MVVM: View → ViewModel → Service
@Observable (iOS 17+ Observation)
SwiftData: City, KazaEntry
UserDefaults + App Group: Ayarlar, cache, PrayerLocation
```

## Teknoloji

- SwiftUI iOS 17+
- Adhan Swift (SPM) — offline namaz vakti
- RevenueCat (SPM) — Pro satın alma
- Aladhan REST API — online vakit + cache
- CoreLocation — opsiyonel konum (Safar, Kıble)

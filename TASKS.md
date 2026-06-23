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
| Phase 5 | Pro özellikler (Seferi + Kaza + Çoklu şehir) + DEV Pro toggle | ✅ |
| Phase 6 | RevenueCat + Pro gating | ✅ |
| Phase 7 | Widget + Dynamic Island + Apple Watch | ✅ |
| Phase 8 | Polish + App Store hazırlık | ✅ |

---

## Son Yapılanlar

- **Konum seçimi yeniden tasarım**: Zorunlu konum izni kaldırıldı, cascading seçim (Ülke → İl → İlçe) eklendi, Türkiye için local JSON datası
- **ShareableContentView**: Discover içerikleri için paylaşılabilir görsel üretimi (Story/Kare format, ImageRenderer)
- **Konum servis düzeltmeleri**: CLLocationManager delegate + MainActor garantisi
- **DEBUG Pro**: `hasProAccess` her zaman true, Settings'te paywall önizleme
- **Asr/Diyanet düzeltmesi**: Diyanet metodu için `recommendedAsrCalculation = .hanafi` eklendi; tüm model init'leri default school için bunu kullanıyor; method değişince Asr otomatik önerilen değere geçiyor. **Migration**: Eski Diyanet kullanıcıları (`school=0`, `hasManuallySetAsrCalculation=false`) için bir kerelik göç ile `school` Hanefi'ye (1) çekiliyor (`StorageService.migrateAsrSchoolIfNeeded()`, `asrSchoolMigrated` flag ile). Kullanıcı manuel seçim yaptıysa göç ezilmiyor.

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

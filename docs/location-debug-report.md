# Vakit App - Konum (Location) Debug Raporu

## Sorun

Kıble Pusulası ve Seferi Hesabı özellikleri için konum izni isteniyor, kullanıcı izin veriyor, ancak **konum hiç gelmiyor** — 25 saniye sonra timeout'a düşüyor.

Sorun **cihaza özgü** (iPhone, iOS 26.5, TestFlight build). Aynı kod simülatörde ve diğer cihazlarda çalışıyor olabilir.

## Neler denendi?

1. **İlk kod:** `CLLocationManager.requestLocation()` — delegate callback'leri (`didUpdateLocations` / `didFailWithError`) hiç tetiklenmedi.
2. **Fix 1:** 15sn timeout eklendi → timeout mesajı gösterildi, ama konum hâlâ gelmedi.
3. **Fix 2 (güncel):** `requestLocation()` yerine `startUpdatingLocation()` + ilk konumda `stopUpdatingLocation()`. Timeout 25sn. `kCLError.locationUnknown` geçici hata olarak ele alınıyor (hemen fail edilmiyor).

## Güncel kod (`LocationService.swift`)

```swift
final class LocationService: NSObject, CLLocationManagerDelegate {
    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var timeoutTask: Task<Void, Never>?

    func requestOneShotLocation() async throws -> CLLocation {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.servicesDisabled
        }
        return try await withCheckedThrowingContinuation { continuation in
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.manager = manager
            self.continuation = continuation

            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(25))
                guard let self, self.continuation != nil else { return }
                await MainActor.run { self.finish(.failure(.timeout)) }
            }

            switch manager.authorizationStatus {
            case .denied, .restricted: finish(.failure(.denied))
            case .notDetermined: manager.requestWhenInUseAuthorization()
            default: manager.startUpdatingLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            finish(.failure(.denied))
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return finish(.failure(.unavailable)) }
        manager.stopUpdatingLocation()
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        finish(.failure(error))
    }
}
```

## Çağrı zinciri

```
QiblaView (buton) → QiblaViewModel.requestLocation() [@MainActor]
  → LocationService.requestOneShotLocation() [async, non-@MainActor]
    → withCheckedThrowingContinuation (closure @MainActor üzerinde çalışır)
      → CLLocationManager() oluşturulur
      → startUpdatingLocation() veya requestWhenInUseAuthorization()
```

## Şüpheli noktalar

1. **MainActor izolasyonu:** `LocationService` `@MainActor` değil, ama `withCheckedThrowingContinuation` closure'ı çağrıldığı actor'de çalışır (QiblaViewModel @MainActor). CLLocationManager main thread'de oluşturuluyor mu?
2. **Delegate referansı:** `CLLocationManager.delegate` weak. `LocationService` instance'ı deallocated oluyor olabilir mi?
3. **TestFlight / Privacy:** `PrivacyInfo.xcprivacy`'de konum için gerekli deklarasyon var mı?
4. **iOS 26.5 özel durumu:** Bu iOS sürümünde `CLLocationManager` delegate davranışı değişmiş olabilir mi?
5. **Precise Location:** Kullanıcı "Kesin Konum" iznini kapatmış olabilir mi? `startUpdatingLocation()` approximate location ile çalışır mı?

## Proje yapısı

```
namaz-swiftui/
├── Vakit/
│   ├── Services/LocationService.swift     ← problemli dosya
│   ├── ViewModels/QiblaViewModel.swift    ← kıble ekranı
│   ├── ViewModels/SafarViewModel.swift    ← seferi ekranı
│   ├── Views/Qibla/QiblaView.swift
│   ├── Views/Qibla/CompassView.swift
│   ├── Views/Safar/SafarView.swift
│   ├── Info.plist                         ← NSLocationWhenInUseUsageDescription mevcut ✓
│   ├── PrivacyInfo.xcprivacy              ← kontrol edilmeli
│   └── Resources/Localizable.xcstrings
└── Shared/AppGroup.swift                  ← group.com.fatihdisci.vakit.shared
```

## Beklenen davranış

Konum izni verildikten sonra **1-3 saniye içinde** `didUpdateLocations` delegate'i tetiklenmeli. Modern iPhone'larda GPS sıcak başlangıcı anlık olmalı.

## Notlar

- Kullanıcı iPhone, iOS 26.5, TestFlight build
- WiFi ve 5G açık
- Hem Kıble hem Seferi aynı hatayı veriyor (ortak nokta: `LocationService`)
- `Info.plist`'te `NSLocationWhenInUseUsageDescription` mevcut
- `NSLocationAlwaysAndWhenInUseUsageDescription` de mevcut (gereksiz ama zararsız)

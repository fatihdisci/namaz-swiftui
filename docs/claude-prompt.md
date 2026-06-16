# iOS Location Bug — Fix This

## Problem

iOS uygulamasında (SwiftUI, iOS 17+, iPhone gerçek cihaz, TestFlight build) Kıble Pusulası ve Seferi Hesabı için konum izni isteniyor, kullanıcı "Allow While Using App" veriyor, ama **`CLLocationManager` delegate'leri hiç tetiklenmiyor**. Ne `didUpdateLocations` ne `didFailWithError`. 25 saniye timeout sonrası hata mesajı gösteriliyor. Normalde bir iPhone'da konum 1-3 saniyede gelmeli.

## Environment
- iOS 26.5 (gerçek cihaz, TestFlight)
- SwiftUI, @Observable, Swift Concurrency (async/await)
- Xcode 26, Swift 6
- `Info.plist`'te `NSLocationWhenInUseUsageDescription` mevcut
- `PrivacyInfo.xcprivacy`'de `NSPrivacyCollectedDataTypePreciseLocation` deklare edilmiş

## Current Code (LocationService.swift)

```swift
import Foundation
import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {
    enum LocationError: Error, LocalizedError {
        case denied
        case unavailable
        case timeout
        case servicesDisabled
        var errorDescription: String? {
            switch self {
            case .denied: "Location permission denied"
            case .unavailable: "Location unavailable"
            case .timeout: "Location request timed out"
            case .servicesDisabled: "Location services are disabled"
            }
        }
    }

    private static let timeoutSeconds: TimeInterval = 25
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
                try? await Task.sleep(for: .seconds(Self.timeoutSeconds))
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

    private func finish(_ result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        timeoutTask?.cancel()
        timeoutTask = nil
        self.continuation = nil
        manager?.delegate = nil
        manager = nil
        continuation.resume(with: result)
    }

    // MARK: - CLLocationManagerDelegate

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
        guard let location = locations.first else {
            finish(.failure(.unavailable))
            return
        }
        manager.stopUpdatingLocation()
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        finish(.failure(error))
    }
}
```

## Call Chain

```
QiblaView button tap
  → QiblaViewModel.requestLocation() [@MainActor class]
    → LocationService.requestOneShotLocation() [non-@MainActor]
      → withCheckedThrowingContinuation closure [runs on MainActor context]
        → CLLocationManager() created
        → delegate = self
        → startUpdatingLocation()
        → ... delegate callback NEVER fires
```

## What We've Tried

1. `CLLocationManager.requestLocation()` — delegate hiç tetiklenmedi
2. `CLLocationManager.startUpdatingLocation()` — delegate hâlâ tetiklenmiyor
3. Timeout 15sn → 25sn — timeout çalışıyor ama konum gelmiyor
4. `kCLError.locationUnknown` geçici hata handling — etkisiz
5. `locationServicesEnabled()` check — true dönüyor
6. Hem Kıble hem Seferi aynı sorun (ikisi de LocationService kullanıyor)

## Key Observations

- **`locationManagerDidChangeAuthorization` tetikleniyor** (kullanıcı izin verince `startUpdatingLocation()` çağrılıyor)
- Ama sonrasında **`didUpdateLocations` ASLA tetiklenmiyor**
- **`didFailWithError` da tetiklenmiyor** — yani sessizce hiçbir şey olmuyor
- Timeout 25 saniye sonra devreye giriyor
- Maps gibi diğer uygulamalarda konum çalışıyor (cihaz GPS'i sağlam)

## Your Task

Find and fix the root cause. Consider:
- Swift 6 / MainActor isolation issues with CLLocationManagerDelegate
- CLLocationManager lifecycle (weak delegate reference?)
- iOS 26.5 specific behavior changes
- TestFlight entitlement restrictions
- Threading: is the manager truly created on main thread with active run loop?
- `PrivacyInfo.xcprivacy` requirements for iOS 26.5+

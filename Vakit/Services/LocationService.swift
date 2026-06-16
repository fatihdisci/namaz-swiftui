import Foundation
import CoreLocation

/// Tek seferlik konum servisi.
/// ANAYASA KURALI: Konum asla kalıcı saklanmaz — istek biter bitmez
/// manager ve konum referansı bırakılır.
///
/// ⚠️ Bu sınıfın `@MainActor` olması ZORUNLUDUR — kaldırma.
/// CLLocationManager, delegate callback'lerini *kendisinin başlatıldığı
/// thread'in run loop'unda* iletir (Apple dokümantasyonu). Swift Concurrency'nin
/// arka plan (cooperative pool) thread'lerinin aktif run loop'u YOKTUR. Manager
/// orada oluşturulup başlatılırsa `didUpdateLocations`/`didFailWithError` HİÇ
/// tetiklenmez; sadece timeout devreye girer.
///
/// `requestOneShotLocation()` `nonisolated async` olsaydı (sınıf MainActor
/// değilken olduğu gibi), `@MainActor` bir çağırandan bile arka plan thread'ine
/// "hop" ederdi (SE-0338) ve manager run loop'suz bir thread'de doğardı.
/// Sınıfı MainActor'a sabitleyerek manager'ın daima main thread'de (aktif run
/// loop'lu) oluşturulmasını garanti ediyoruz.
@MainActor
final class LocationService: NSObject {
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

    /// İzin ister (gerekirse) ve tek bir konum okuması döner.
    /// `startUpdatingLocation()` + ilk sonuçta durdurma kullanır.
    /// 25 saniye timeout ile korunur (soğuk GPS ilk fix ~15-20 sn sürebilir).
    func requestOneShotLocation() async throws -> CLLocation {
        // `locationServicesEnabled()` senkrondur ve main thread'i uzun süre
        // bloke edebilir (Apple runtime uyarısı verir) → arka planda kontrol et.
        guard await Self.servicesEnabled() else {
            throw LocationError.servicesDisabled
        }

        // Bu closure MainActor'da (sınıf @MainActor) senkron çalışır → manager
        // main thread'in aktif run loop'unda oluşturulur. Delegate callback'leri
        // de bu run loop'ta teslim edilir.
        return try await withCheckedThrowingContinuation { continuation in
            // Askıda kalmış önceki bir istek varsa sızıntıyı önlemek için bitir.
            if self.continuation != nil {
                finish(.failure(LocationError.unavailable))
            }

            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.manager = manager
            self.continuation = continuation

            // Timeout: bu Task @MainActor context'ini miras alır (kapsayan metot
            // MainActor), sleep sonrası main'de devam eder.
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(Self.timeoutSeconds))
                guard let self, self.continuation != nil else { return }
                self.finish(.failure(LocationError.timeout))
            }

            switch manager.authorizationStatus {
            case .denied, .restricted:
                finish(.failure(LocationError.denied))
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                // İzin zaten varsa doğrudan başlat. İlk konum gelince stop.
                manager.startUpdatingLocation()
            }
        }
    }

    /// `CLLocationManager.locationServicesEnabled()` main thread'i bloke
    /// edebileceğinden arka plan thread'inde çağrılır.
    private static func servicesEnabled() async -> Bool {
        await Task.detached(priority: .userInitiated) {
            CLLocationManager.locationServicesEnabled()
        }.value
    }

    private func finish(_ result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        timeoutTask?.cancel()
        timeoutTask = nil
        self.continuation = nil
        manager?.stopUpdatingLocation()
        manager?.delegate = nil
        manager = nil
        continuation.resume(with: result)
    }
}

// MARK: - CLLocationManagerDelegate
//
// Sınıf @MainActor ve manager main thread'de oluşturulduğu için Core Location
// bu callback'leri main run loop'ta iletir. Bu yüzden metotlar `nonisolated` +
// `MainActor.assumeIsolated` ile yazılır (projedeki QiblaViewModel heading
// pattern'iyle aynı): protokol uyumu sağlanır ve @MainActor state'ine
// (continuation, manager) güvenle erişilir.
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            guard continuation != nil else { return }
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                finish(.failure(LocationError.denied))
            case .notDetermined:
                break // Kullanıcı henüz seçim yapmadı.
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            guard let location = locations.first else {
                finish(.failure(LocationError.unavailable))
                return
            }
            // İlk konum alındı — finish() stopUpdatingLocation çağırıp bitirir.
            finish(.success(location))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            // kCLError.locationUnknown: geçici hata, konum henüz mevcut değil.
            // startUpdatingLocation otomatik tekrar deneyecek — hemen fail etme.
            if let clError = error as? CLError, clError.code == .locationUnknown {
                return
            }
            finish(.failure(error))
        }
    }
}

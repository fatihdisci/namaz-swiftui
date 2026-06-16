import Foundation
import CoreLocation

/// Tek seferlik konum servisi.
/// ANAYASA KURALI: Konum asla kalıcı saklanmaz — istek biter bitmez
/// manager ve konum referansı bırakılır.
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

    /// İzin ister (gerekirse) ve tek bir konum okuması döner.
    /// `startUpdatingLocation()` + ilk sonuçta durdurma kullanır — `requestLocation()`
    /// bazı cihazlarda / iOS sürümlerinde delegate'i hiç tetiklemeyebiliyor.
    /// 25 saniye timeout ile korunur (soğuk GPS ilk fix ~15-20 sn sürebilir).
    func requestOneShotLocation() async throws -> CLLocation {
        // Sistem konum servisleri kapalıysa hemen hata dön.
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.servicesDisabled
        }

        return try await withCheckedThrowingContinuation { continuation in
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.manager = manager
            self.continuation = continuation

            // Timeout: 25 saniye sonra otomatik iptal (soğuk GPS toleransı).
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(Self.timeoutSeconds))
                guard let self, self.continuation != nil else { return }
                await MainActor.run {
                    self.finish(.failure(LocationError.timeout))
                }
            }

            let status = manager.authorizationStatus
            switch status {
            case .denied, .restricted:
                finish(.failure(LocationError.denied))
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                // startUpdatingLocation: requestLocation'dan daha agresif,
                // delegate'i garantili tetikler. İlk konum gelince stop.
                manager.startUpdatingLocation()
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
        // CLLocationManager delegate callback'leri dökümante olarak main thread'de
        // çağrılır. DispatchQueue.main.async KULLANMA — Swift concurrency
        // runtime'ının @MainActor context'ini kuramamasına sebep olur.
        continuation.resume(with: result)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // startUpdatingLocation kullan — requestLocation'dan daha güvenilir.
            manager.startUpdatingLocation()
        case .denied, .restricted:
            finish(.failure(LocationError.denied))
        case .notDetermined:
            break // Kullanıcı henüz seçim yapmadı.
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            finish(.failure(LocationError.unavailable))
            return
        }
        // İlk konum alındı — güncellemeyi durdur ve başarıyla bitir.
        manager.stopUpdatingLocation()
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // kCLError.locationUnknown: geçici hata, konum henüz mevcut değil.
        // startUpdatingLocation otomatik tekrar deneyecek — hemen fail etme.
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
        finish(.failure(error))
    }
}

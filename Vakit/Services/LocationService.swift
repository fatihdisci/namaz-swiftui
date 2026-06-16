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

    private static let timeoutSeconds: TimeInterval = 15

    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var timeoutTask: Task<Void, Never>?

    /// İzin ister (gerekirse) ve tek bir konum okuması döner.
    /// 15 saniye timeout ile korunur — bu sürede yanıt gelmezse `.timeout` hatası döner.
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

            // Timeout: 15 saniye sonra otomatik iptal.
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
                manager.requestLocation()
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
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(LocationError.denied))
        case .notDetermined:
            break // Kullanıcı henüz seçim yapmadı.
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            finish(.success(location))
        } else {
            finish(.failure(LocationError.unavailable))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(error))
    }
}

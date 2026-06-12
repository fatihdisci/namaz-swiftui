import Foundation
import CoreLocation

/// Tek seferlik konum servisi.
/// ANAYASA KURALI: Konum asla kalıcı saklanmaz — istek biter bitmez
/// manager ve konum referansı bırakılır.
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum LocationError: Error {
        case denied
        case unavailable
    }

    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<CLLocation, Error>?

    /// İzin ister (gerekirse) ve tek bir konum okuması döner.
    func requestOneShotLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.manager = manager
            self.continuation = continuation

            switch manager.authorizationStatus {
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
        self.continuation = nil
        manager?.delegate = nil
        manager = nil
        // CLLocationManager delegate callback'i her zaman main thread'de
        // çağrılır, ama defensive olarak DispatchQueue.main ile garantile.
        DispatchQueue.main.async {
            continuation.resume(with: result)
        }
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

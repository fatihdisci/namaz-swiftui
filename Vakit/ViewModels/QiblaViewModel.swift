import Foundation
import CoreLocation

/// Kıble ekranının durumu: konum + pusula yönü.
/// ANAYASA KURALI: Konum asla kalıcı saklanmaz.
@Observable
@MainActor
final class QiblaViewModel: NSObject {
    enum LocationState: Equatable {
        case idle
        case loading
        case granted(CLLocationCoordinate2D)
        case denied
        /// Lokalizasyon anahtarı (örn. "error.location").
        case error(String)

        static func == (lhs: LocationState, rhs: LocationState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.denied, .denied):
                return true
            case let (.granted(a), .granted(b)):
                return a.latitude == b.latitude && a.longitude == b.longitude
            case let (.error(a), .error(b)):
                return a == b
            default:
                return false
            }
        }
    }

    private(set) var locationState: LocationState = .idle

    /// Cihazın baktığı yön (kuzeyden derece, saat yönünde).
    private(set) var heading: Double = 0

    /// Konumdan Kabe'ye olan açı (kuzeyden derece, saat yönünde).
    private(set) var qiblaAngle: Double = 0

    /// Pusula iğnesinin ekranda göstereceği açı: kıble açısı - cihaz yönü.
    var needleRotation: Double {
        qiblaAngle - heading
    }

    @ObservationIgnored private let locationService: LocationService
    @ObservationIgnored private var headingManager: CLLocationManager?

    init(locationService: LocationService = LocationService()) {
        self.locationService = locationService
        super.init()
    }

    /// Tek seferlik konum ister, kıble açısını hesaplar ve pusula güncellemelerini başlatır.
    func requestLocation() async {
        locationState = .loading
        do {
            let location = try await locationService.requestOneShotLocation()
            qiblaAngle = QiblaService.qiblaDirection(from: location.coordinate)
            locationState = .granted(location.coordinate)
            startHeadingUpdates()
        } catch LocationService.LocationError.denied {
            locationState = .denied
        } catch {
            locationState = .error("error.location")
        }
    }

    @MainActor
    private func startHeadingUpdates() {
        guard CLLocationManager.headingAvailable() else { return }
        let manager = CLLocationManager()
        manager.delegate = self
        manager.headingFilter = 1
        headingManager = manager
        manager.startUpdatingHeading()
    }

    /// Pusula güncellemelerini durdurur. View kaybolduğunda çağrılır.
    @MainActor
    func stopUpdates() {
        headingManager?.stopUpdatingHeading()
        headingManager?.delegate = nil
        headingManager = nil
    }
}

extension QiblaViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        // CLLocationManager delegate callback'i main thread'de garantidir.
        // assumeIsolated: DispatchQueue.main.async gibi @MainActor context'ini kırmaz,
        // @Observable tracking için gerekli olan actor isolation'ı korur.
        MainActor.assumeIsolated { [weak self] in
            self?.heading = value
        }
    }
}

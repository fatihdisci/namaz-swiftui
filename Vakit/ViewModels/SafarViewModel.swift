import Foundation
import CoreLocation
import Observation

/// Seferi ekranı: ev konumu (yalnızca il/ilçe) ile anlık konum arası mesafe.
/// ANAYASA KURALI: Konum asla kalıcı saklanmaz — sadece mesafe hesaplanır.
@Observable
@MainActor
final class SafarViewModel {
    enum CheckState: Equatable {
        case idle
        case locating
        case result(distanceKm: Double, isSafar: Bool)
        case denied
        /// Lokalizasyon anahtarı (örn. "error.location").
        case error(String)
    }

    private(set) var state: CheckState = .idle

    /// Ev konumu ayrı saklanır; canlı GPS ev olarak tutulmaz.
    var homeLocation: PrayerLocation? { storage.homePrayerLocation ?? storage.selectedPrayerLocation }

    var homeCity: CitySnapshot? {
        homeLocation?.toSnapshot(school: 0)
    }

    @ObservationIgnored private let storage: StorageService
    @ObservationIgnored private let locationService: LocationService

    // locationService default'u init gövdesinde (MainActor) oluşturulur:
    // LocationService @MainActor olduğundan nonisolated default-argument
    // ifadesinde `= LocationService()` yazılamaz.
    init(storage: StorageService = .shared, locationService: LocationService? = nil) {
        self.storage = storage
        self.locationService = locationService ?? LocationService()
    }

    func refreshHomeLocation() {
        state = .idle
    }

    /// Tek seferlik konum alır, ev şehrine mesafeyi hesaplar.
    @MainActor
    func checkDistance() async {
        guard let home = homeLocation else {
            state = .error("safar.noHomeCity")
            return
        }

        state = .locating
        do {
            let location = try await locationService.requestOneShotLocation()
            let homeCoord = CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)
            let distance = SafarService.distanceKm(from: homeCoord, to: location.coordinate)
            state = .result(distanceKm: distance, isSafar: SafarService.isSafar(distanceKm: distance))
        } catch LocationService.LocationError.denied {
            state = .denied
        } catch LocationService.LocationError.servicesDisabled {
            state = .error("error.locationServicesDisabled")
        } catch LocationService.LocationError.timeout {
            state = .error("error.locationTimeout")
        } catch {
            state = .error("error.location")
        }
        // Konum referansı burada biter — hiçbir yerde saklanmaz.
    }
}

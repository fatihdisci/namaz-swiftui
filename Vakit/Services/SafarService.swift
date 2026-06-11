import Foundation
import CoreLocation

/// Seferi mesafe hesabı. Diyanet, Hanefî mezhebine göre seferîlik
/// eşiğini yaklaşık 90 km olarak esas alır.
enum SafarService {
    /// Seferi eşiği (km) — Diyanet ~90 km.
    static let thresholdKm = 90.0

    private static let earthRadiusKm = 6371.0

    /// İki koordinat arası kuş uçuşu mesafe (km) — Haversine.
    static func distanceKm(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = degreesToRadians(origin.latitude)
        let lat2 = degreesToRadians(destination.latitude)
        let deltaLat = degreesToRadians(destination.latitude - origin.latitude)
        let deltaLon = degreesToRadians(destination.longitude - origin.longitude)

        let haversine = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let clamped = min(1, max(0, haversine))
        let centralAngle = 2 * atan2(sqrt(clamped), sqrt(1 - clamped))

        return earthRadiusKm * centralAngle
    }

    /// Mesafe seferi eşiğini aşıyor mu?
    static func isSafar(distanceKm: Double) -> Bool {
        distanceKm >= thresholdKm
    }

    private static func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }
}

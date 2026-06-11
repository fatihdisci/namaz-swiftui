import Foundation
import CoreLocation

/// Verilen konumdan Kabe'ye olan kıble açısını hesaplar.
enum QiblaService {
    /// Kabe koordinatları.
    static let kaaba = CLLocationCoordinate2D(latitude: 21.422487, longitude: 39.826206)

    /// Büyük daire (great-circle) başlangıç açısı: kuzeyden saat yönünde, 0-360 derece.
    static func qiblaDirection(from coordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = degreesToRadians(coordinate.latitude)
        let lon1 = degreesToRadians(coordinate.longitude)
        let lat2 = degreesToRadians(kaaba.latitude)
        let lon2 = degreesToRadians(kaaba.longitude)

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        let bearing = radiansToDegrees(atan2(y, x))
        return normalizeDegrees(bearing)
    }

    private static func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }

    private static func radiansToDegrees(_ value: Double) -> Double {
        value * 180 / .pi
    }

    private static func normalizeDegrees(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized < 0 ? normalized + 360 : normalized
    }
}

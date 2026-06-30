import Foundation

enum ProFeaturePolicy {
    static let freeSavedCityLimit = 2
    static let proSavedCityLimit = 10

    static func savedCityLimit(hasProAccess: Bool) -> Int {
        hasProAccess ? proSavedCityLimit : freeSavedCityLimit
    }

    static func canAddSavedCity(
        currentCount: Int,
        isNewLocation: Bool,
        hasProAccess: Bool
    ) -> Bool {
        !isNewLocation || currentCount < savedCityLimit(hasProAccess: hasProAccess)
    }

    static func trimmedSavedCities(
        _ locations: [PrayerLocation],
        selectedLocation: PrayerLocation?,
        hasProAccess: Bool
    ) -> [PrayerLocation] {
        let limit = savedCityLimit(hasProAccess: hasProAccess)
        guard locations.count > limit else { return locations }

        var result: [PrayerLocation] = []
        if let selectedLocation,
           let selected = locations.first(where: { $0.id == selectedLocation.id }) {
            result.append(selected)
        }

        for location in locations where !result.contains(where: { $0.id == location.id }) {
            guard result.count < limit else { break }
            result.append(location)
        }

        return result
    }
}

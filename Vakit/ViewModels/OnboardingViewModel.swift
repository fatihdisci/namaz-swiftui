import Foundation
import CoreLocation
import Observation
import SwiftData

@Observable
@MainActor
final class OnboardingViewModel {
    var searchQuery: String = "" {
        didSet { scheduleSearch() }
    }
    var results: [CitySnapshot] = []
    var selectedCity: CitySnapshot?
    var method: CalculationMethod = .default
    var isSearching = false
    var isLocating = false
    var errorKey: String?

    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private let storage: StorageService
    @ObservationIgnored private let locationService = LocationService()

    private static let searchDebounce: Duration = .milliseconds(400)

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    // MARK: - Şehir arama (Aladhan /cityInfo)

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: Self.searchDebounce)
            guard !Task.isCancelled else { return }
            await self?.search(query: query)
        }
    }

    /// Aladhan /cityInfo tek şehir doğrular (liste API'si yok).
    /// "Şehir, Ülke" yazılırsa ikisi ayrılır; ülke yoksa dile göre varsayılan kullanılır.
    private func search(query: String) async {
        isSearching = true
        errorKey = nil
        defer { isSearching = false }

        let parts = query.split(separator: ",", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        let cityName = parts.first ?? query
        let country = parts.count > 1
            ? parts[1]
            : (storage.language == "tr" ? "Turkey" : "")

        var components = URLComponents(string: "https://api.aladhan.com/v1/cityInfo")
        components?.queryItems = [
            URLQueryItem(name: "city", value: cityName),
            URLQueryItem(name: "country", value: country),
        ]
        guard let url = components?.url else { return }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, _) = try await URLSession.shared.data(for: request)
            guard !Task.isCancelled else { return }

            let payload = try JSONDecoder().decode(AladhanCityInfoResponse.self, from: data)
            guard
                payload.code == 200,
                let info = payload.data,
                let latitude = info.latitude?.value,
                let longitude = info.longitude?.value
            else {
                results = []
                errorKey = "onboarding.city.noResults"
                return
            }

            results = [
                CitySnapshot(
                    name: cityName,
                    latitude: latitude,
                    longitude: longitude,
                    country: country,
                    timezone: info.timezone ?? TimeZone.current.identifier,
                    method: method
                )
            ]
        } catch is CancellationError {
            // Yeni arama başladı; sessiz geç.
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            errorKey = "error.noInternet"
        }
    }

    // MARK: - Konumdan şehir

    func useCurrentLocation() async {
        isLocating = true
        errorKey = nil
        defer { isLocating = false }

        do {
            let location = try await locationService.requestOneShotLocation()
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                errorKey = "error.location"
                return
            }

            let city = CitySnapshot(
                name: placemark.locality ?? placemark.administrativeArea ?? "?",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                country: placemark.country ?? "",
                timezone: placemark.timeZone?.identifier ?? TimeZone.current.identifier,
                method: method
            )
            selectedCity = city
            results = [city]
        } catch LocationService.LocationError.denied {
            errorKey = "qibla.permissionDenied"
        } catch {
            errorKey = "error.location"
        }
        // Konum referansı burada biter — hiçbir yerde saklanmaz.
    }

    // MARK: - Kaydet

    func select(_ city: CitySnapshot) {
        selectedCity = city
    }

    /// Şehri SwiftData'ya + App Group snapshot'ına yazar.
    func saveSelectedCity(context: ModelContext) {
        guard var snapshot = selectedCity else { return }
        snapshot.method = method

        let city = snapshot.makeCity()
        city.isPrimary = true
        context.insert(city)
        try? context.save()

        storage.selectedCity = snapshot
        storage.selectedCityID = snapshot.id
        storage.method = method
    }
}

// MARK: - Aladhan /cityInfo yanıt modelleri

struct AladhanCityInfoResponse: Decodable {
    let code: Int
    let data: CityInfoData?

    struct CityInfoData: Decodable {
        let latitude: FlexibleDouble?
        let longitude: FlexibleDouble?
        let timezone: String?
    }
}

/// Aladhan sayısal alanları bazen String bazen Double döndürür; ikisini de kabul et.
struct FlexibleDouble: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self), let double = Double(string) {
            value = double
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected Double or numeric String"
            )
        }
    }
}

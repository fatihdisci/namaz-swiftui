import Foundation
import Observation

/// Cascading konum seçimi ViewModel'i.
/// Akış: Ülke → Admin1 (İl/State) → Admin2 (İlçe/City).
/// TR için yerel JSON datası kullanılır; diğer ülkeler için Aladhan API.
@Observable
@MainActor
final class LocationSelectionViewModel {
    // MARK: - State

    var selectedCountryCode: String
    var selectedCountryName: String
    var selectedAdmin1: AdminUnit?
    var selectedAdmin2: AdminUnit?

    /// Yerel datası olan ülkeler için cascading seçim aktif mi?
    var useCascadingFlow: Bool
    var method: CalculationMethod

    // Manually entered city for non-Turkey countries
    var manualCityQuery: String = ""
    var manualCityResults: [CitySnapshot] = []
    var selectedManualCity: CitySnapshot?
    var isSearching: Bool = false
    var errorKey: String?

    // Country picker
    var countries: [CountryOption] = []
    var showCountryPicker: Bool = false

    // Admin lists (for Turkey)
    var admin1List: [AdminUnit] = []
    var admin2List: [AdminUnit] = []

    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private let locationData: LocationDataService
    @ObservationIgnored private let storage: StorageService

    private static let searchDebounce: Duration = .milliseconds(400)

    // MARK: - Init

    init(
        locationData: LocationDataService = .shared,
        storage: StorageService = .shared
    ) {
        self.locationData = locationData
        self.storage = storage

        let detectedCode = locationData.detectedCountryCode
        self.selectedCountryCode = detectedCode
        self.selectedCountryName = ""
        self.useCascadingFlow = locationData.hasLocalData(for: detectedCode)
        self.method = storage.method

        setupCountries()
        updateCountryName()
        updateMethod()
        loadAdmin1List()
    }

    // MARK: - Label helpers (instance, delegates to static)

    var admin1Label: String {
        PrayerLocation.admin1Label(for: selectedCountryCode)
    }

    var admin2Label: String {
        PrayerLocation.admin2Label(for: selectedCountryCode)
    }

    /// Seçim tamamlandı mı?
    var canContinue: Bool {
        if useCascadingFlow {
            return selectedAdmin1 != nil && selectedAdmin2 != nil
        } else {
            return selectedManualCity != nil
        }
    }

    // MARK: - Country

    private func setupCountries() {
        let lang = storage.language
        countries = locationData.allCountries(language: lang)
        updateCountryName()
    }

    private func updateCountryName() {
        if let match = countries.first(where: { $0.code == selectedCountryCode }) {
            selectedCountryName = match.name
        }
    }

    func selectCountry(_ country: CountryOption) {
        guard country.code != selectedCountryCode else { return }
        selectedCountryCode = country.code
        selectedCountryName = country.name
        useCascadingFlow = country.hasCascadingData
        updateMethod()
        resetSelections()
        loadAdmin1List()
    }

    private func updateMethod() {
        method = PrayerLocation.defaultMethod(for: selectedCountryCode)
    }

    private func resetSelections() {
        selectedAdmin1 = nil
        selectedAdmin2 = nil
        selectedManualCity = nil
        manualCityQuery = ""
        manualCityResults = []
        errorKey = nil
        admin2List = []
    }

    // MARK: - Cascading flow (Turkey)

    private func loadAdmin1List() {
        guard useCascadingFlow else {
            admin1List = []
            return
        }
        switch selectedCountryCode {
        case "TR":
            admin1List = locationData.turkeyProvinces()
        default:
            admin1List = []
        }
    }

    func selectAdmin1(_ admin: AdminUnit) {
        selectedAdmin1 = admin
        selectedAdmin2 = nil
        loadAdmin2List()
    }

    private func loadAdmin2List() {
        guard useCascadingFlow, let admin1 = selectedAdmin1 else {
            admin2List = []
            return
        }
        switch selectedCountryCode {
        case "TR":
            admin2List = locationData.turkeyDistricts(for: admin1.name)
        default:
            admin2List = []
        }
    }

    func selectAdmin2(_ admin: AdminUnit) {
        selectedAdmin2 = admin
    }

    // MARK: - Manual search (non-Turkey)

    func searchCity(query: String) {
        manualCityQuery = query
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            manualCityResults = []
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: Self.searchDebounce)
            guard !Task.isCancelled else { return }
            await self?.performSearch(query: trimmed)
        }
    }

    private func performSearch(query: String) async {
        isSearching = true
        errorKey = nil
        defer { isSearching = false }

        // Aladhan /cityInfo API
        var components = URLComponents(string: "https://api.aladhan.com/v1/cityInfo")
        components?.queryItems = [
            URLQueryItem(name: "city", value: query),
            URLQueryItem(name: "country", value: selectedCountryName),
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
                manualCityResults = []
                errorKey = "onboarding.city.noResults"
                return
            }

            manualCityResults = [
                CitySnapshot(
                    name: query,
                    latitude: latitude,
                    longitude: longitude,
                    country: selectedCountryName,
                    timezone: info.timezone ?? TimeZone.current.identifier,
                    method: method
                )
            ]
        } catch is CancellationError {
            // yeni arama başladı
        } catch {
            guard !Task.isCancelled else { return }
            manualCityResults = []
            errorKey = "error.noInternet"
        }
    }

    func selectManualCity(_ city: CitySnapshot) {
        selectedManualCity = city
    }

    // MARK: - Build PrayerLocation

    /// Mevcut seçimden `PrayerLocation` üretir.
    func buildPrayerLocation() -> PrayerLocation? {
        if useCascadingFlow {
            guard let admin1 = selectedAdmin1, let admin2 = selectedAdmin2 else { return nil }

            let districtName: String
            let cityName: String
            if selectedCountryCode == "TR" {
                districtName = admin2.name
                cityName = admin1.name
            } else {
                districtName = ""
                cityName = admin2.name
            }

            return PrayerLocation(
                countryCode: selectedCountryCode,
                countryName: selectedCountryName,
                admin1Name: admin1.name,
                admin1Type: PrayerLocation.admin1Label(for: selectedCountryCode),
                admin2Name: admin2.name,
                admin2Type: PrayerLocation.admin2Label(for: selectedCountryCode),
                cityName: cityName,
                districtName: districtName,
                latitude: admin2.latitude,
                longitude: admin2.longitude,
                timeZoneIdentifier: admin2.timezone,
                calculationMethod: method
            )
        } else {
            guard let city = selectedManualCity else { return nil }
            return PrayerLocation(
                countryCode: selectedCountryCode,
                countryName: selectedCountryName,
                admin1Name: "",
                admin1Type: "",
                admin2Name: city.name,
                admin2Type: PrayerLocation.admin2Label(for: selectedCountryCode),
                cityName: city.name,
                districtName: "",
                latitude: city.latitude,
                longitude: city.longitude,
                timeZoneIdentifier: city.timezone,
                calculationMethod: method
            )
        }
    }
}

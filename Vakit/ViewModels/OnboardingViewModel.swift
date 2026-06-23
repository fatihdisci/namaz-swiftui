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
    var method: CalculationMethod = .default {
        didSet {
            guard method != oldValue else { return }
            asrCalculation = method.recommendedAsrCalculation
        }
    }
    var asrCalculation: AsrCalculation
    var isSearching = false
    var isLocating = false
    var errorKey: String?

    /// Yeni cascading konum seçimi için ViewModel (isteğe bağlı).
    /// Onboarding yeni akışta LocationSelectionViewModel kullanır;
    /// Settings'ten açılan sheet eski CitySelectionView ile çalışır.
    var locationSelectionVM: LocationSelectionViewModel?

    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private let storage: StorageService
    @ObservationIgnored private let locationService = LocationService()

    /// iller.json'dan yüklenen tüm Türkiye ilçeleri.
    @ObservationIgnored private static var ilceler: [Ilce] = {
        guard let url = Bundle.main.url(forResource: "iller", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Ilce].self, from: data)
        } catch {
            return []
        }
    }()

    /// dunya_sehirleri.json'dan yüklenen 60 dünya şehri.
    @ObservationIgnored private static var dunyaSehirleri: [DunyaSehri] = {
        guard let url = Bundle.main.url(forResource: "dunya_sehirleri", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([DunyaSehri].self, from: data)
        } catch {
            return []
        }
    }()

    private static let searchDebounce: Duration = .milliseconds(200)

    init(storage: StorageService = .shared) {
        self.storage = storage
        self.asrCalculation = AsrCalculation(rawValue: storage.school) ?? .standard
    }

    // MARK: - Şehir arama (iller.json yerel veri)

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: Self.searchDebounce)
            guard !Task.isCancelled else { return }
            self?.search(query: query)
        }
    }

    /// iller.json + dunya_sehirleri.json içinde il/ilçe veya ülke/şehir adına filtrele.
    /// Türkçe karakter duyarsız. TR sonuçları önce, dünya sonuçları sonra.
    private func search(query: String) {
        isSearching = true
        errorKey = nil
        defer { isSearching = false }

        let normalizedQuery = query
            .lowercased()
            .replacingOccurrences(of: "i̇", with: "i")
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "i\u{0307}", with: "i")

        // Türkiye ilçeleri
        let trMatches = Self.ilceler.filter { ilce in
            ilce.normalizedSearch.contains(normalizedQuery)
        }

        let trResults = trMatches.prefix(20).map { ilce in
            CitySnapshot(
                name: ilce.displayName,
                latitude: ilce.lat,
                longitude: ilce.lng,
                country: "Turkey",
                timezone: "Europe/Istanbul",
                method: method
            )
        }

        // Dünya şehirleri
        let worldMatches = Self.dunyaSehirleri.filter { sehir in
            sehir.normalizedSearch.contains(normalizedQuery)
        }

        let worldResults = worldMatches.prefix(15).map { sehir in
            CitySnapshot(
                name: sehir.displayName,
                latitude: sehir.lat,
                longitude: sehir.lng,
                country: sehir.ulke,
                timezone: TimeZone.current.identifier,
                method: method
            )
        }

        results = Array((trResults + worldResults).prefix(30))

        if results.isEmpty {
            errorKey = "onboarding.city.noResults"
        }
    }

    // MARK: - Konumdan şehir (opsiyonel, Ayarlar'dan kullanılır)

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
        snapshot.school = asrCalculation.rawValue

        // Tek birincil şehir: mevcut kayıtların isPrimary işaretini kaldır.
        let existing = (try? context.fetch(FetchDescriptor<City>())) ?? []
        existing.forEach { $0.isPrimary = false }

        let city = snapshot.makeCity()
        city.isPrimary = true
        context.insert(city)
        try? context.save()

        storage.selectedCity = snapshot
        storage.selectedCityID = snapshot.id
        storage.method = method
        storage.school = snapshot.school
    }

    /// Seçilen `PrayerLocation`'ı kaydeder (cascading konum seçiminden gelir).
    func saveSelectedLocation(_ location: PrayerLocation, context: ModelContext) {
        storage.selectedPrayerLocation = location
        storage.method = location.calculationMethod
        storage.school = location.school

        // SwiftData'ya da yaz (geriye uyumluluk).
        let existing = (try? context.fetch(FetchDescriptor<City>())) ?? []
        existing.forEach { $0.isPrimary = false }

        let city = location.makeCity()
        city.isPrimary = true
        context.insert(city)
        try? context.save()

        storage.selectedCityID = location.id
    }
}

// MARK: - Aladhan /cityInfo yanıt modelleri (LocationSelectionViewModel tarafından kullanılır)

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

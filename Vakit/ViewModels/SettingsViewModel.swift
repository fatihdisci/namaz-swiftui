import Foundation
import CoreLocation
import Observation
import SwiftData
import WidgetKit

/// Ayarlar: dil, şehir, ev şehri, hesaplama metodu.
/// Her değişiklik App Group snapshot'ına + SwiftData'ya yazılır ve bildirimler yeniden planlanır.
@Observable
@MainActor
final class SettingsViewModel {
    var method: CalculationMethod
    private(set) var city: CitySnapshot?
    private(set) var location: PrayerLocation?
    private(set) var homeLocation: PrayerLocation?
    var isLocating = false
    var errorKey: String?

    @ObservationIgnored private let storage: StorageService
    @ObservationIgnored private let notificationService: NotificationService
    @ObservationIgnored private let locationService: LocationService

    init(
        storage: StorageService = .shared,
        notificationService: NotificationService = .shared,
        locationService: LocationService? = nil
    ) {
        self.storage = storage
        self.notificationService = notificationService
        self.locationService = locationService ?? LocationService()
        self.method = storage.method
        self.city = storage.selectedCity
        self.location = storage.selectedPrayerLocation
        self.homeLocation = storage.homePrayerLocation ?? storage.selectedPrayerLocation
    }

    /// UI'da gösterilecek konum adı.
    var locationDisplayName: String {
        if let loc = location {
            return loc.displayName
        }
        return city?.name ?? "—"
    }

    var homeLocationDisplayName: String {
        (homeLocation ?? storage.selectedPrayerLocation)?.displayName ?? "—"
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    func setMethod(_ newMethod: CalculationMethod, context: ModelContext) {
        guard newMethod != method else { return }
        method = newMethod
        storage.method = newMethod
        updateSelectedLocation(context: context) {
            $0.calculationMethod = newMethod
        }
    }

    /// Yeni cascading konum seçiminden kaydeder.
    func saveLocation(_ location: PrayerLocation, context: ModelContext) {
        storage.selectedPrayerLocation = location
        storage.method = location.calculationMethod
        self.location = location
        self.method = location.calculationMethod
        city = location.toSnapshot(school: 0)

        // SwiftData'yı da güncelle.
        let existing = (try? context.fetch(FetchDescriptor<City>())) ?? []
        existing.forEach { $0.isPrimary = false }

        let cityModel = location.makeCity(school: 0)
        cityModel.isPrimary = true
        context.insert(cityModel)
        try? context.save()

        storage.selectedCityID = location.id
        rescheduleNotifications()
    }

    func saveHomeLocation(_ location: PrayerLocation) {
        storage.homePrayerLocation = location
        homeLocation = location
    }

    /// Hesabı ve tüm kullanıcı verisini kalıcı olarak siler (App Store 5.1.1(v)).
    /// Sıra: SwiftData → yerel ayarlar/önbellek → bildirimler → widget → Apple/RevenueCat.
    func deleteAccount(context: ModelContext) async {
        // 1. SwiftData: şehirler ve kaza kayıtları.
        for city in (try? context.fetch(FetchDescriptor<City>())) ?? [] {
            context.delete(city)
        }
        for entry in (try? context.fetch(FetchDescriptor<KazaEntry>())) ?? [] {
            context.delete(entry)
        }
        try? context.save()

        // 2. App Group: konum, kaza sayaçları, bildirim ayarları, önbellek, onboarding.
        storage.wipeUserData()

        // 3. Bekleyen bildirimleri iptal et.
        notificationService.cancelAll()

        // 4. Home Screen widget snapshot'ını temizle ve yenile.
        WidgetSnapshotStore.clear()
        WidgetCenter.shared.reloadAllTimelines()

        // 5. Apple oturumu + RevenueCat bağlantısını kaldır.
        await AuthService.shared.deleteAccount()

        // 6. Yerel yayınlanan durumu sıfırla.
        city = nil
        location = nil
        homeLocation = nil
        method = storage.method

        // 7. Uygulamayı onboarding'e döndür.
        NotificationCenter.default.post(name: .vakitAccountDeleted, object: nil)
    }

    func useAutomaticLocation(context: ModelContext) async {
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

            let prayerLocation = PrayerLocation(
                countryCode: placemark.isoCountryCode ?? "",
                countryName: placemark.country ?? "",
                admin1Name: placemark.administrativeArea ?? "",
                admin1Type: PrayerLocation.admin1Label(for: placemark.isoCountryCode ?? ""),
                admin2Name: placemark.locality ?? placemark.subAdministrativeArea ?? "",
                admin2Type: PrayerLocation.admin2Label(for: placemark.isoCountryCode ?? ""),
                cityName: placemark.locality ?? placemark.administrativeArea ?? "",
                districtName: placemark.subLocality ?? "",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timeZoneIdentifier: placemark.timeZone?.identifier ?? TimeZone.current.identifier,
                calculationMethod: PrayerLocation.defaultMethod(for: placemark.isoCountryCode ?? "")
            )
            saveLocation(prayerLocation, context: context)
        } catch LocationService.LocationError.denied {
            errorKey = "qibla.permissionDenied"
        } catch {
            errorKey = "error.location"
        }
    }

    /// Şehir seçim sheet'i kapandıktan sonra çağrılır: snapshot'ı tazele, bildirimleri planla.
    func refreshCity() {
        city = storage.selectedCity
        location = storage.selectedPrayerLocation
        homeLocation = storage.homePrayerLocation ?? storage.selectedPrayerLocation
        method = storage.method
        rescheduleNotifications()
    }

    private func updateSelectedLocation(context: ModelContext, mutate: (inout PrayerLocation) -> Void) {
        guard var loc = storage.selectedPrayerLocation else {
            // Eski model varsa onu güncelle.
            updateSelectedCity(context: context) { snapshot in
                snapshot.method = method
            }
            return
        }
        mutate(&loc)
        storage.selectedPrayerLocation = loc
        storage.method = loc.calculationMethod
        location = loc
        city = loc.toSnapshot(school: 0)

        // SwiftData'yı da güncelle.
        let cityID = loc.id
        let descriptor = FetchDescriptor<City>(predicate: #Predicate { $0.id == cityID })
        if let stored = try? context.fetch(descriptor).first {
            stored.method = loc.calculationMethod
            stored.school = 0
            try? context.save()
        }

        rescheduleNotifications()
    }

    private func updateSelectedCity(context: ModelContext, mutate: (inout CitySnapshot) -> Void) {
        guard var snapshot = storage.selectedCity else { return }
        mutate(&snapshot)
        storage.selectedCity = snapshot
        city = snapshot

        // SwiftData'daki kalıcı şehir kaydını da güncelle.
        let cityID = snapshot.id
        let descriptor = FetchDescriptor<City>(predicate: #Predicate { $0.id == cityID })
        if let stored = try? context.fetch(descriptor).first {
            stored.method = snapshot.method
            stored.school = 0
            try? context.save()
        }

        rescheduleNotifications()
    }

    private func rescheduleNotifications() {
        guard let city = storage.resolvedCity else { return }
        Task {
            await notificationService.reschedule(city: city)
        }
    }
}

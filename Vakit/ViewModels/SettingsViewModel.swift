import Foundation
import Observation
import SwiftData

/// Ayarlar: dil, şehir, hesaplama metodu, mezhep.
/// Her değişiklik App Group snapshot'ına + SwiftData'ya yazılır ve bildirimler yeniden planlanır.
@Observable
@MainActor
final class SettingsViewModel {
    var method: CalculationMethod
    var school: Int
    private(set) var city: CitySnapshot?
    private(set) var location: PrayerLocation?

    @ObservationIgnored private let storage: StorageService
    @ObservationIgnored private let notificationService: NotificationService

    init(
        storage: StorageService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.storage = storage
        self.notificationService = notificationService
        self.method = storage.method
        self.school = storage.school
        self.city = storage.selectedCity
        self.location = storage.selectedPrayerLocation
    }

    /// UI'da gösterilecek konum adı.
    var locationDisplayName: String {
        if let loc = location {
            return loc.displayName
        }
        return city?.name ?? "—"
    }

    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    func setMethod(_ newMethod: CalculationMethod, context: ModelContext) {
        guard newMethod != method else { return }
        method = newMethod
        storage.method = newMethod
        updateSelectedLocation(context: context) {
            $0.calculationMethod = newMethod
        }
    }

    func setSchool(_ newSchool: Int, context: ModelContext) {
        guard newSchool != school else { return }
        school = newSchool
        storage.school = newSchool
        updateSelectedCity(context: context) {
            $0.school = newSchool
        }
    }

    /// Yeni cascading konum seçiminden kaydeder.
    func saveLocation(_ location: PrayerLocation, context: ModelContext) {
        storage.selectedPrayerLocation = location
        storage.method = location.calculationMethod
        self.location = location
        self.method = location.calculationMethod
        city = location.toSnapshot(school: school)

        // SwiftData'yı da güncelle.
        let existing = (try? context.fetch(FetchDescriptor<City>())) ?? []
        existing.forEach { $0.isPrimary = false }

        let cityModel = location.makeCity(school: school)
        cityModel.isPrimary = true
        context.insert(cityModel)
        try? context.save()

        storage.selectedCityID = location.id
        rescheduleNotifications()
    }

    /// Şehir seçim sheet'i kapandıktan sonra çağrılır: snapshot'ı tazele, bildirimleri planla.
    func refreshCity() {
        city = storage.selectedCity
        location = storage.selectedPrayerLocation
        method = storage.method
        school = storage.school
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
        city = loc.toSnapshot(school: school)

        // SwiftData'yı da güncelle.
        let cityID = loc.id
        let descriptor = FetchDescriptor<City>(predicate: #Predicate { $0.id == cityID })
        if let stored = try? context.fetch(descriptor).first {
            stored.method = loc.calculationMethod
            stored.school = school
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
            stored.school = snapshot.school
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

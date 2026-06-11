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
        updateSelectedCity(context: context) {
            $0.method = newMethod
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

    /// Şehir seçim sheet'i kapandıktan sonra çağrılır: snapshot'ı tazele, bildirimleri planla.
    func refreshCity() {
        city = storage.selectedCity
        method = storage.method
        school = storage.school
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
        guard let city = storage.selectedCity?.makeCity() else { return }
        Task {
            await notificationService.reschedule(city: city)
        }
    }
}

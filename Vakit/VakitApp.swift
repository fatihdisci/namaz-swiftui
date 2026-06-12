import SwiftUI
import SwiftData

@main
struct VakitApp: App {
    @State private var languageService = LanguageService.shared
    @State private var notificationService = NotificationService.shared
    @State private var purchaseService = PurchaseService.shared
    @State private var showOnboarding = !StorageService.shared.onboardingDone

    init() {
        PurchaseService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(languageService)
                .environment(notificationService)
                .environment(purchaseService)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        showOnboarding = false
                        Task {
                            await rescheduleNotifications()
                        }
                    }
                    .environment(languageService)
                }
                .task {
                    if !showOnboarding {
                        await rescheduleNotifications()
                    }
                    await purchaseService.refresh()
                }
        }
        .modelContainer(for: [City.self, KazaEntry.self])
    }

    /// Seçili konum için bildirimleri yeniden planlar (uygulama açılışı + onboarding sonrası).
    private func rescheduleNotifications() async {
        // Yeni PrayerLocation veya eski CitySnapshot üzerinden City oluştur.
        if let location = StorageService.shared.selectedPrayerLocation {
            await notificationService.reschedule(city: location.makeCity())
        } else if let city = StorageService.shared.selectedCity?.makeCity() {
            await notificationService.reschedule(city: city)
        }
    }
}

import SwiftUI
import SwiftData

@main
struct VakitApp: App {
    @State private var languageService = LanguageService.shared
    @State private var notificationService = NotificationService.shared
    @State private var showOnboarding = !StorageService.shared.onboardingDone

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(languageService)
                .environment(notificationService)
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
                }
        }
        .modelContainer(for: [City.self, KazaEntry.self])
    }

    /// Seçili şehir için bildirimleri yeniden planlar (uygulama açılışı + onboarding sonrası).
    private func rescheduleNotifications() async {
        guard let city = StorageService.shared.selectedCity?.makeCity() else { return }
        await notificationService.reschedule(city: city)
    }
}

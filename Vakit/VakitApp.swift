import SwiftUI
import SwiftData

@main
struct VakitApp: App {
    @State private var languageService = LanguageService.shared
    @State private var notificationService = NotificationService.shared
    @State private var purchaseService = PurchaseService.shared
    @State private var authService = AuthService.shared
    @State private var showOnboarding = !StorageService.shared.onboardingDone

    @Environment(\.scenePhase) private var scenePhase

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
                .environment(authService)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        StorageService.shared.onboardingDone = true
                        StorageService.shared.shouldShowSetupCompleteCard = true
                        NotificationCenter.default.post(name: .vakitSetupCompleteCardShouldShow, object: nil)
                        showOnboarding = false
                        Task {
                            await rescheduleNotifications()
                        }
                    }
                    .environment(languageService)
                    .environment(notificationService)
                }
                .task {
                    if !showOnboarding {
                        await rescheduleNotifications()
                    }
                    await purchaseService.refresh()
                    await authService.refreshCredentialState()
                    if await RemoteContentService.shared.refreshIfNeeded() {
                        DailyContent.reload()
                        NotificationCenter.default.post(name: .vakitContentUpdated, object: nil)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    // Foreground'a dönünce vakit cache'i + Home Screen widget'ını tazele.
                    if newPhase == .active {
                        Task {
                            await rescheduleNotifications()
                            WidgetSnapshotWriter.refreshFromCache(
                                language: languageService.currentLanguage
                            )
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .vakitAccountDeleted)) { _ in
                    // Hesap silindi: uygulamayı sıfır onboarding durumuna döndür.
                    showOnboarding = true
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

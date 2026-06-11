import SwiftUI
import SwiftData

@main
struct VakitApp: App {
    @State private var languageService = LanguageService.shared
    @State private var showOnboarding = !StorageService.shared.onboardingDone

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(languageService)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        showOnboarding = false
                    }
                    .environment(languageService)
                }
        }
        .modelContainer(for: [City.self, KazaEntry.self])
    }
}

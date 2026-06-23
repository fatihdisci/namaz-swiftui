import SwiftUI

enum AppTab: Hashable {
    case home
    case discover
    case tools
    case settings
}

struct ContentView: View {
    private let whatsNewVersion = "1.1.0"

    @State private var selectedTab: AppTab = .home
    @State private var homeViewModel = HomeViewModel()
    @State private var showWhatsNew = false

    @Environment(LanguageService.self) private var lang

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel, onOpenDiscover: { selectedTab = .discover })
                .tabItem {
                    Label(lang.t("tab.home"), systemImage: "house.fill")
                }
                .tag(AppTab.home)

            NavigationStack {
                DiscoverView()
            }
                .tabItem {
                    Label(lang.t("tab.discover"), systemImage: "book.fill")
                }
                .tag(AppTab.discover)

            ToolsView()
                .tabItem {
                    Label(lang.t("tab.tools"), systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.tools)

            SettingsView()
                .tabItem {
                    Label(lang.t("tab.settings"), systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(.vakitAccent)
        .task {
            showWhatsNewIfNeeded()
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewSheet(version: whatsNewVersion) {
                StorageService.shared.lastSeenWhatsNewVersion = whatsNewVersion
            }
            .environment(lang)
        }
    }

    private func showWhatsNewIfNeeded() {
        let storage = StorageService.shared
        guard storage.onboardingDone else { return }
        guard storage.lastSeenWhatsNewVersion != whatsNewVersion else { return }
        showWhatsNew = true
    }
}

#Preview {
    ContentView()
        .environment(LanguageService.shared)
}

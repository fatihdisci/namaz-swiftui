import SwiftUI

enum AppTab: Hashable {
    case home
    case discover
    case tools
    case settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homeViewModel = HomeViewModel()

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
    }
}

#Preview {
    ContentView()
        .environment(LanguageService.shared)
}

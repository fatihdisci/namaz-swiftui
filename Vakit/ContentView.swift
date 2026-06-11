import SwiftUI

struct ContentView: View {
    @State private var homeViewModel = HomeViewModel()

    @Environment(LanguageService.self) private var lang

    var body: some View {
        TabView {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label(lang.t("tab.home"), systemImage: "house.fill")
                }

            QiblaPlaceholderView()
                .tabItem {
                    Label(lang.t("tab.qibla"), systemImage: "location.north.line.fill")
                }

            SettingsPlaceholderView()
                .tabItem {
                    Label(lang.t("tab.settings"), systemImage: "gearshape.fill")
                }
        }
        .tint(.vakitAccent)
    }
}

private struct QiblaPlaceholderView: View {
    @Environment(LanguageService.self) private var lang

    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            Text(lang.t("tab.qibla"))
                .foregroundStyle(Color.vakitText)
        }
    }
}

private struct SettingsPlaceholderView: View {
    @Environment(LanguageService.self) private var lang

    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            Text(lang.t("tab.settings"))
                .foregroundStyle(Color.vakitText)
        }
    }
}

#Preview {
    ContentView()
        .environment(LanguageService.shared)
}

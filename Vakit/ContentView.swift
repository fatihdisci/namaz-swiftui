import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomePlaceholderView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            QiblaPlaceholderView()
                .tabItem {
                    Label("Qibla", systemImage: "location.north.line.fill")
                }

            SettingsPlaceholderView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.vakitAccent)
    }
}

private struct HomePlaceholderView: View {
    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            Text("Home")
                .foregroundStyle(Color.vakitText)
        }
    }
}

private struct QiblaPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            Text("Qibla")
                .foregroundStyle(Color.vakitText)
        }
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            Text("Settings")
                .foregroundStyle(Color.vakitText)
        }
    }
}

#Preview {
    ContentView()
}

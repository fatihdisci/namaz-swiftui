import SwiftUI
import UIKit

struct QiblaView: View {
    @State private var viewModel = QiblaViewModel()

    @Environment(LanguageService.self) private var lang
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .fajr)

            VStack(spacing: 24) {
                Text(lang.t("qibla.title"))
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
                    .padding(.top, 24)

                Spacer()

                content

                Spacer()

                privacyNote
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .onDisappear {
            viewModel.stopUpdates()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.locationState {
        case .idle:
            actionButton(titleKey: "qibla.findButton") {
                Task { await viewModel.requestLocation() }
            }

        case .loading:
            ProgressView()
                .tint(Color.vakitAccent)

        case .granted:
            CompassView(viewModel: viewModel)

        case .denied:
            VStack(spacing: 16) {
                Text(lang.t("qibla.permissionDenied"))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.vakitTextDim)

                actionButton(titleKey: "qibla.openSettings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }

        case .error(let messageKey):
            VStack(spacing: 16) {
                Text(lang.t(messageKey))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.vakitTextDim)

                actionButton(titleKey: "qibla.retry") {
                    Task { await viewModel.requestLocation() }
                }
            }
        }
    }

    private func actionButton(titleKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(lang.t(titleKey))
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.vakitText)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.vakitAccent)
                .clipShape(Capsule())
        }
    }

    private var privacyNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.shield")
                .font(.footnote)
            Text(lang.t("qibla.locationNote"))
                .font(.footnote)
        }
        .foregroundStyle(Color.vakitTextDim)
    }
}

#Preview {
    QiblaView()
        .environment(LanguageService.shared)
        .preferredColorScheme(.dark)
}

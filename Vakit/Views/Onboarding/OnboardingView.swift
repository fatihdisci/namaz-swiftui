import SwiftUI
import SwiftData

enum OnboardingStep {
    case welcome
    case locationSelection
    case notificationIntro
    case ready
}

/// Tam ekran onboarding akışı: karşılama → konum seçimi → bildirim tanıtımı → hazır.
/// Konum izni onboarding'de otomatik istenmez. Bildirim sistem izni yalnızca
/// kendi tanıtım ekranındaki kullanıcı aksiyonundan sonra istenir.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var viewModel = OnboardingViewModel()
    @State private var locationVM = LocationSelectionViewModel()
    @State private var selectedLocation: PrayerLocation?

    @Environment(LanguageService.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .vakitAccent)

            Group {
                switch step {
                case .welcome:
                    WelcomeStepView {
                        step = .locationSelection
                    }
                    .transition(stepTransition)
                case .locationSelection:
                    NavigationStack {
                        LocationSelectionView(viewModel: locationVM) { location in
                            selectedLocation = location
                            viewModel.saveSelectedLocation(location, context: modelContext)
                            step = .notificationIntro
                        }
                    }
                    .transition(stepTransition)
                case .notificationIntro:
                    NotificationPermissionView {
                        step = .ready
                    }
                    .transition(stepTransition)
                case .ready:
                    ReadyStepView(location: selectedLocation) {
                        onComplete()
                    }
                    .transition(stepTransition)
                }
            }
            .animation(vakitAnimation(.vakitMedium, reduceMotion: reduceMotion), value: step)
        }
        .preferredColorScheme(.dark)
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

private struct ReadyStepView: View {
    let location: PrayerLocation?
    let onOpen: () -> Void

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 58, weight: .medium))
                    .foregroundStyle(Color.vakitAccent)

                Text(lang.t("onboarding.ready.title"))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.vakitText)
                    .multilineTextAlignment(.center)

                Text(lang.t("onboarding.ready.body"))
                    .font(.vakitBody)
                    .foregroundStyle(Color.vakitTextDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            summaryCard
                .padding(.top, 28)
                .padding(.horizontal, 24)

            Spacer()

            Button {
                onOpen()
            } label: {
                Text(lang.t("onboarding.ready.open"))
                    .font(.vakitHeadline)
                    .foregroundStyle(Color.vakitText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vakitAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 0) {
            summaryRow(
                icon: "mappin.and.ellipse",
                titleKey: "onboarding.ready.city",
                value: location?.shortName ?? "—"
            )

            divider

            summaryRow(
                icon: "function",
                titleKey: "onboarding.ready.method",
                value: lang.t((location?.calculationMethod ?? .default).localizationKey)
            )

            divider

            summaryRow(
                icon: "sun.max",
                titleKey: "onboarding.ready.asr",
                value: lang.t(AsrCalculation(rawValue: location?.school ?? AsrCalculation.standard.rawValue)?.localizationKey ?? AsrCalculation.standard.localizationKey)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }

    private func summaryRow(icon: String, titleKey: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 24)

            Text(lang.t(titleKey))
                .font(.vakitBody)
                .foregroundStyle(Color.vakitText)

            Spacer()

            Text(value)
                .font(.vakitCaption)
                .foregroundStyle(Color.vakitTextDim)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Divider().overlay(Color.vakitBorder)
    }
}

#Preview {
    OnboardingView {}
        .environment(LanguageService.shared)
        .environment(NotificationService.shared)
        .modelContainer(for: [City.self, KazaEntry.self], inMemory: true)
}

import SwiftUI
import SwiftData

enum OnboardingStep {
    case welcome
    case locationSelection
    case notifications
}

/// Tam ekran onboarding akışı: karşılama → konum seçimi (ülke → il → ilçe) → bildirim izni.
/// Konum izni onboarding'de İSTENMEZ. Kullanıcı konumunu manuel seçer.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var viewModel = OnboardingViewModel()
    @State private var locationVM = LocationSelectionViewModel()

    @Environment(\.modelContext) private var modelContext

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
                        LocationSelectionView(viewModel: locationVM) {
                            viewModel.saveSelectedLocation(from: locationVM, context: modelContext)
                            step = .notifications
                        }
                    }
                    .transition(stepTransition)
                case .notifications:
                    NotificationPermissionView {
                        onComplete()
                    }
                    .transition(stepTransition)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: step)
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

#Preview {
    OnboardingView {}
        .environment(LanguageService.shared)
        .modelContainer(for: [City.self, KazaEntry.self], inMemory: true)
}

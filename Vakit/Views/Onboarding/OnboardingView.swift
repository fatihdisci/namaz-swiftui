import SwiftUI

enum OnboardingStep {
    case welcome
    case citySelection
    case notifications
}

/// Tam ekran onboarding akışı: karşılama → şehir/metod → bildirim izni.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .vakitAccent)

            Group {
                switch step {
                case .welcome:
                    WelcomeStepView {
                        step = .citySelection
                    }
                    .transition(stepTransition)
                case .citySelection:
                    CitySelectionView(viewModel: viewModel) {
                        step = .notifications
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
}

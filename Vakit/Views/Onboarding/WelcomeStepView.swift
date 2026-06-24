import SwiftUI

struct WelcomeStepView: View {
    let onContinue: () -> Void

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(lang.t("app.name"))
                    .font(.vakitHero)
                    .foregroundStyle(Color.vakitText)

                Text(lang.t("onboarding.welcome.subtitle"))
                    .font(.vakitBody)
                    .foregroundStyle(Color.vakitTextDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onContinue) {
                Text(lang.t("onboarding.welcome.start"))
                    .font(.vakitHeadline)
                    .foregroundStyle(Color.vakitText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vakitAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ZStack {
        Color.vakitBg.ignoresSafeArea()
        WelcomeStepView {}
    }
    .environment(LanguageService.shared)
}

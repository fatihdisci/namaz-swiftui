import SwiftUI
import UserNotifications

/// Bildirim izni adımı. İzin verilsin ya da verilmesin onboarding tamamlanır.
struct NotificationPermissionView: View {
    let onFinish: () -> Void

    @Environment(LanguageService.self) private var lang
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(Color.vakitAccent)

                Text(lang.t("onboarding.notifications.title"))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.vakitText)
                    .multilineTextAlignment(.center)

                Text(lang.t("onboarding.notifications.body"))
                    .font(.vakitBody)
                    .foregroundStyle(Color.vakitTextDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(lang.t("onboarding.notifications.privacy"))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestPermission()
                } label: {
                    Text(lang.t("onboarding.notifications.allow"))
                        .font(.vakitHeadline)
                        .foregroundStyle(Color.vakitText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.vakitAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(isRequesting)

                Button {
                    complete()
                } label: {
                    Text(lang.t("onboarding.notifications.skip"))
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(Color.vakitTextDim)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isRequesting = false
            complete()
        }
    }

    private func complete() {
        StorageService.shared.onboardingDone = true
        onFinish()
    }
}

#Preview {
    ZStack {
        Color.vakitBg.ignoresSafeArea()
        NotificationPermissionView {}
    }
    .environment(LanguageService.shared)
}

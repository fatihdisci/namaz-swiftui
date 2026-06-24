import SwiftUI

/// 6 vakit için bildirim aç/kapa + "kaç dakika önce" ayarı.
/// ANAYASA KURALI: Her vakit bağımsız — birini kapatmak diğerlerini etkilemez.
struct NotificationSettingsView: View {
    @State private var settings: NotificationSettings
    @State private var fridayReminderEnabled: Bool
    @State private var motivationalNotesEnabled: Bool
    @State private var isAuthorized = true

    @Environment(LanguageService.self) private var lang
    @Environment(\.openURL) private var openURL

    private let storage: StorageService
    private let notificationService: NotificationService

    private static let minuteOptions = [0, 5, 10, 20, 30]

    init(storage: StorageService = .shared, notificationService: NotificationService = .shared) {
        self.storage = storage
        self.notificationService = notificationService
        _settings = State(initialValue: storage.notificationSettings)
        _fridayReminderEnabled = State(initialValue: storage.fridayReminderEnabled)
        _motivationalNotesEnabled = State(initialValue: storage.motivationalNotesEnabled)
    }

    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    if !isAuthorized {
                        notificationDisabledBanner
                    }

                    ForEach(Prayer.allCases) { prayer in
                        card(for: prayer)
                    }

                    fridayReminderCard

                    motivationalNotesCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(lang.t("settings.notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isAuthorized = await notificationService.requestPermission()
        }
    }

    // MARK: - Disabled banner

    private var notificationDisabledBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.vakitError)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.vakitError.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(lang.t("notification.disabled.title"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
                Text(lang.t("notification.disabled.body"))
                    .font(.vakitReference)
                    .foregroundStyle(Color.vakitTextDim)
            }

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text(lang.t("notification.disabled.action"))
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(Color.vakitBg)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.vakitAccent)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.vakitError.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Card

    private func card(for prayer: Prayer) -> some View {
        let setting = settings.setting(for: prayer)

        return VStack(spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                Image(systemName: prayer.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(prayer.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(prayer.accentColor.opacity(0.12)))

                Text(lang.t(prayer.localizationKey))
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(Color.vakitText)

                Spacer()

                Toggle(
                    "",
                    isOn: Binding(
                        get: { setting.enabled },
                        set: { update(prayer: prayer, enabled: $0, minutesBefore: setting.minutesBefore) }
                    )
                )
                .labelsHidden()
                .tint(prayer.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Picker (shown when enabled)
            if setting.enabled {
                Divider()
                    .overlay(Color.vakitBorder)
                    .padding(.horizontal, 16)

                Picker(
                    lang.t("settings.notifications"),
                    selection: Binding(
                        get: { setting.minutesBefore },
                        set: { update(prayer: prayer, enabled: setting.enabled, minutesBefore: $0) }
                    )
                ) {
                    ForEach(Self.minuteOptions, id: \.self) { minutes in
                        Text(minuteLabel(minutes))
                            .tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
        }
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var fridayReminderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.vakitAccent.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(lang.t("friday.reminder.title"))
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(Color.vakitText)
                Text(lang.t("friday.reminder.subtitle"))
                    .font(.vakitReference)
                    .foregroundStyle(Color.vakitTextDim)
            }

            Spacer()

            Toggle("", isOn: $fridayReminderEnabled)
                .labelsHidden()
                .tint(Color.vakitAccent)
                .onChange(of: fridayReminderEnabled) { _, enabled in
                    storage.fridayReminderEnabled = enabled
                    guard let city = storage.resolvedCity else { return }
                    Task { await notificationService.reschedule(city: city) }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.vakitBorder))
    }

    private var motivationalNotesCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.vakitAccent.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(lang.t("notification.motivational.title"))
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(Color.vakitText)
                Text(lang.t("notification.motivational.subtitle"))
                    .font(.vakitReference)
                    .foregroundStyle(Color.vakitTextDim)
            }

            Spacer()

            Toggle("", isOn: $motivationalNotesEnabled)
                .labelsHidden()
                .tint(Color.vakitAccent)
                .onChange(of: motivationalNotesEnabled) { _, enabled in
                    storage.motivationalNotesEnabled = enabled
                    guard let city = storage.resolvedCity else { return }
                    Task { await notificationService.reschedule(city: city) }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.vakitBorder))
    }

    private func minuteLabel(_ minutes: Int) -> String {
        minutes == 0
            ? lang.t("notification.option.atTimeShort")
            : String(format: lang.t("notification.option.minutesBeforeShort"), minutes)
    }

    private func update(prayer: Prayer, enabled: Bool, minutesBefore: Int) {
        settings.update(prayer: prayer, enabled: enabled, minutesBefore: minutesBefore)
        storage.notificationSettings = settings

        guard let city = storage.resolvedCity else { return }
        Task {
            await notificationService.reschedule(city: city)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environment(LanguageService.shared)
    .preferredColorScheme(.dark)
}

import SwiftUI

/// 6 vakit için bildirim aç/kapa + "kaç dakika önce" ayarı.
/// ANAYASA KURALI: Her vakit bağımsız — birini kapatmak diğerlerini etkilemez.
struct NotificationSettingsView: View {
    @State private var settings: NotificationSettings
    @State private var fridayReminderEnabled: Bool

    @Environment(LanguageService.self) private var lang

    private let storage: StorageService
    private let notificationService: NotificationService

    private static let minuteOptions = [0, 5, 10, 20, 30]

    init(storage: StorageService = .shared, notificationService: NotificationService = .shared) {
        self.storage = storage
        self.notificationService = notificationService
        _settings = State(initialValue: storage.notificationSettings)
        _fridayReminderEnabled = State(initialValue: storage.fridayReminderEnabled)
    }

    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Prayer.allCases) { prayer in
                        card(for: prayer)
                    }

                    fridayReminderCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(lang.t("settings.notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.requestPermission()
        }
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
            .padding(.vertical, 14)

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
                    .font(.caption)
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
        .padding(.vertical, 14)
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

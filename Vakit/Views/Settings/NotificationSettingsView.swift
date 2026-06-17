import SwiftUI

/// 6 vakit için bildirim aç/kapa + "kaç dakika önce" ayarı.
/// ANAYASA KURALI: Her vakit bağımsız — birini kapatmak diğerlerini etkilemez.
struct NotificationSettingsView: View {
    @State private var settings: NotificationSettings

    @Environment(LanguageService.self) private var lang

    private let storage: StorageService
    private let notificationService: NotificationService

    private static let minuteOptions = [0, 5, 10, 20, 30]

    init(storage: StorageService = .shared, notificationService: NotificationService = .shared) {
        self.storage = storage
        self.notificationService = notificationService
        _settings = State(initialValue: storage.notificationSettings)
    }

    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()

            List {
                ForEach(Prayer.allCases) { prayer in
                    row(for: prayer)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(lang.t("settings.notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.requestPermission()
        }
    }

    private func row(for prayer: Prayer) -> some View {
        let setting = settings.setting(for: prayer)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: prayer.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(prayer.accentColor)
                    .frame(width: 24)

                Text(lang.t(prayer.localizationKey))
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
                .tint(.vakitAccent)
            }

            if setting.enabled {
                Picker(
                    lang.t("settings.notifications"),
                    selection: Binding(
                        get: { setting.minutesBefore },
                        set: { update(prayer: prayer, enabled: setting.enabled, minutesBefore: $0) }
                    )
                ) {
                    ForEach(Self.minuteOptions, id: \.self) { minutes in
                        Text(minuteLabel(minutes)).tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.vakitSurface)
    }

    private func minuteLabel(_ minutes: Int) -> String {
        minutes == 0
            ? lang.t("notification.option.atTime")
            : lang.t("notification.option.minutesBefore", minutes)
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

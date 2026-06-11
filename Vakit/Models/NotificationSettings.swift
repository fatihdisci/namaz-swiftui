import Foundation

/// Tek bir vakit için bildirim ayarı.
struct PrayerNotificationSetting: Codable, Equatable {
    let prayer: Prayer
    var enabled: Bool
    /// 0, 10, 20 veya 30 — vaktin kaç dakika öncesinde bildirim gönderilsin.
    var minutesBefore: Int

    init(prayer: Prayer, enabled: Bool = true, minutesBefore: Int = 0) {
        self.prayer = prayer
        self.enabled = enabled
        self.minutesBefore = minutesBefore
    }
}

/// 6 vaktin tamamı için bildirim ayarları.
struct NotificationSettings: Codable, Equatable {
    var settings: [PrayerNotificationSetting]

    /// Varsayılan: tüm vakitler açık, vaktinde (0 dk önce) bildirim.
    static let `default` = NotificationSettings(
        settings: Prayer.allCases.map { PrayerNotificationSetting(prayer: $0) }
    )

    func setting(for prayer: Prayer) -> PrayerNotificationSetting {
        settings.first { $0.prayer == prayer } ?? PrayerNotificationSetting(prayer: prayer)
    }

    mutating func update(prayer: Prayer, enabled: Bool, minutesBefore: Int) {
        if let index = settings.firstIndex(where: { $0.prayer == prayer }) {
            settings[index].enabled = enabled
            settings[index].minutesBefore = minutesBefore
        } else {
            settings.append(PrayerNotificationSetting(prayer: prayer, enabled: enabled, minutesBefore: minutesBefore))
        }
    }
}

import Foundation
import UserNotifications

/// Vakit bildirimlerini yönetir: izin, planlama ve iptal.
/// ANAYASA KURALI: Her vakit bağımsız bir bildirim — biri kapatılınca diğerleri etkilenmez.
@Observable
final class NotificationService {
    static let shared = NotificationService()

    private static let scheduleDays = 7

    @ObservationIgnored private let storage: StorageService
    @ObservationIgnored private let prayerService: PrayerTimeService
    @ObservationIgnored private let languageService: LanguageService
    @ObservationIgnored private let center: UNUserNotificationCenter

    private(set) var isAuthorized = false

    init(
        storage: StorageService = .shared,
        prayerService: PrayerTimeService = .shared,
        languageService: LanguageService = .shared,
        center: UNUserNotificationCenter = .current()
    ) {
        self.storage = storage
        self.prayerService = prayerService
        self.languageService = languageService
        self.center = center
    }

    /// Bildirim izni henüz sorulmadıysa ister. Daha önce karar verildiyse mevcut durumu döner.
    @discardableResult
    func requestPermission() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
            return true
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            isAuthorized = granted
            return granted
        default:
            isAuthorized = false
            return false
        }
    }

    /// Bekleyen tüm bildirimleri iptal eder.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Şehrin bugün + sonraki günlerinin vakitlerini çekip bildirimleri yeniden planlar.
    /// İzin yoksa sadece bekleyen bildirimleri temizler.
    func reschedule(city: City) async {
        let settings = await center.notificationSettings()
        let authorized = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
        isAuthorized = authorized

        guard authorized else {
            cancelAll()
            // Bildirim izni olmasa da Home Screen widget'ı güncel kalsın.
            WidgetSnapshotWriter.refreshFromCache(language: languageService.currentLanguage)
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        var times: [Date: PrayerTimes] = [:]
        for offset in 0..<Self.scheduleDays {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: today) else { continue }
            times[date] = await prayerService.getPrayerTimes(city: city, date: date)
        }

        // Taze vakitlerden Home Screen widget snapshot'ını güncelle.
        if let todayTimes = times[today] {
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: today)
            let tomorrowTimes = tomorrowDate.flatMap { times[$0] }
            WidgetSnapshotWriter.update(
                city: city,
                today: todayTimes,
                tomorrow: tomorrowTimes,
                language: languageService.currentLanguage
            )
        }

        await scheduleNotifications(for: city, times: times)
    }

    /// Verilen gün → vakitler eşlemesi için bildirimleri planlar. Önce mevcut bildirimler iptal edilir.
    func scheduleNotifications(for city: City, times: [Date: PrayerTimes]) async {
        cancelAll()

        let settings = storage.notificationSettings
        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: city.timezone) ?? .current

        for (date, prayerTimes) in times {
            // Uç enlem fallback'i yalnızca UI'ın boş kalmaması içindir; yaklaşık
            // saatler ibadet bildirimi olarak kesin vakit gibi planlanmaz.
            guard prayerTimes.isReliableForNotifications else { continue }

            for prayer in Prayer.allCases {
                let setting = settings.setting(for: prayer)
                guard setting.enabled else { continue }

                let triggerDate = prayerTimes.time(for: prayer)
                    .addingTimeInterval(-Double(setting.minutesBefore * 60))
                guard triggerDate > now else { continue }

                let identifier = "\(prayer.rawValue)_\(StorageService.dateKey(for: date))"

                let content = UNMutableNotificationContent()
                let prayerName = languageService.t(prayer.localizationKey)
                content.title = prayerName
                content.body = setting.minutesBefore > 0
                    ? languageService.t("notification.body.remaining", prayerName, setting.minutesBefore)
                    : languageService.t("notification.body.started", prayerName)
                content.sound = .default

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                try? await center.add(request)
            }

            if storage.fridayReminderEnabled,
               calendar.component(.weekday, from: prayerTimes.dhuhr) == 6 {
                let triggerDate = prayerTimes.dhuhr.addingTimeInterval(-60 * 60)
                guard triggerDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = languageService.t("friday.notification.title")
                content.body = languageService.t("friday.notification.body")
                content.sound = .default

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let identifier = "friday_\(StorageService.dateKey(for: date))"
                try? await center.add(
                    UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                )
            }
        }
    }
}

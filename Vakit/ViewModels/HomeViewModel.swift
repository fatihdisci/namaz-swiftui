import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class HomeViewModel {
    var todaysTimes: PrayerTimes?
    var tomorrowsTimes: PrayerTimes?
    var nextPrayer: Prayer = .fajr
    var nextPrayerTime: Date = Date()
    var countdownString: String = ""
    var hijriDate: String = ""
    var dailyVerse: Verse?
    var isLoading: Bool = false
    var currentCity: City?
    var savedLocations: [PrayerLocation] = []
    var needsOnboarding: Bool = false

    private let storage: StorageService
    private let prayerService: PrayerTimeService
    private let languageService: LanguageService

    init(
        storage: StorageService = .shared,
        prayerService: PrayerTimeService = .shared,
        languageService: LanguageService = .shared
    ) {
        self.storage = storage
        self.prayerService = prayerService
        self.languageService = languageService
        self.dailyVerse = DailyContent.dailyVerse()

        currentCity = storage.resolvedCity
        savedLocations = storage.savedPrayerLocations

        if currentCity == nil {
            needsOnboarding = true
        }
    }

    /// Bugün + yarın vakitlerini yükler, sonraki 7 günü cache'e doldurur.
    func load() async {
        dailyVerse = DailyContent.dailyVerse()
        savedLocations = storage.savedPrayerLocations

        guard let city = currentCity ?? storage.resolvedCity else {
            needsOnboarding = true
            return
        }
        currentCity = city
        needsOnboarding = false
        isLoading = true
        defer { isLoading = false }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: city.timezone) ?? .current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        async let todayTask = prayerService.getPrayerTimes(city: city, date: today)
        async let tomorrowTask = prayerService.getPrayerTimes(city: city, date: tomorrow)
        let (todayTimes, tomorrowTimes) = await (todayTask, tomorrowTask)

        todaysTimes = todayTimes
        tomorrowsTimes = tomorrowTimes
        hijriDate = Self.hijriDateText(from: todayTimes)
        tick(date: Date())

        // Home Screen widget snapshot'ını güncelle.
        WidgetSnapshotWriter.update(
            city: city,
            today: todayTimes,
            tomorrow: tomorrowTimes,
            language: languageService.currentLanguage
        )

        // Kalan günleri arka planda cache'le (UI'ı bekletme).
        Task { await prayerService.prefetch(city: city) }
    }

    func reloadForLocationChange() async {
        currentCity = storage.resolvedCity
        savedLocations = storage.savedPrayerLocations
        todaysTimes = nil
        tomorrowsTimes = nil
        await load()
    }

    func selectLocation(_ location: PrayerLocation) async {
        storage.selectedPrayerLocation = location
        await reloadForLocationChange()
    }

    func refreshSavedLocations() {
        savedLocations = storage.savedPrayerLocations
    }

    func refreshDailyContent() {
        dailyVerse = DailyContent.dailyVerse()
    }

    private static func hijriDateText(from times: PrayerTimes) -> String {
        let monthName = PrayerTimeService.displayHijriMonthName(times.hijriMonthName)
        return "\(times.hijriDay) \(monthName) \(times.hijriYear)"
    }

    /// Her saniye View'dan (TimelineView) çağrılır: geri sayımı ve sıradaki vakti günceller.
    func tick(date: Date) {
        guard let today = todaysTimes else {
            // Onboarding az önce bitmiş olabilir: şehir geldiyse veriyi yükle.
            if !isLoading, storage.resolvedCity != nil {
                Task { await load() }
            }
            return
        }

        // Gün değiştiyse (gece yarısı) verileri yeniden yükle.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: currentCity?.timezone ?? "") ?? .current
        if calendar.startOfDay(for: date) != today.date, !isLoading {
            Task { await load() }
            return
        }

        let next = prayerService.nextPrayer(from: today, tomorrow: tomorrowsTimes, at: date)
        nextPrayer = next.prayer
        nextPrayerTime = next.time
        countdownString = countdownString(until: next.time, from: date)
    }

    /// String Catalog üzerinden geri sayım metni.
    /// TR: "2s 34dk sonra" / "34dk sonra" / "Az kaldı"
    /// EN: "in 2h 34m" / "in 34m" / "Almost time"
    func countdownString(until target: Date, from now: Date) -> String {
        let interval = max(0, target.timeIntervalSince(now))

        if interval < 60 {
            return languageService.t("countdown.soon")
        }

        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return languageService.t("countdown.minutes", minutes)
        }
        return languageService.t("countdown.hoursMinutes", hours, minutes)
    }

    /// Liste için satır durumları.
    func rowState(for prayer: Prayer, at date: Date = Date()) -> (time: Date, isPast: Bool, isNext: Bool) {
        guard let today = todaysTimes else {
            return (Date(), false, false)
        }
        let time = today.time(for: prayer)
        let isNext = prayer == nextPrayer && Calendar.current.isDate(time, inSameDayAs: date)
        return (time, time <= date, isNext)
    }

    var isFriday: Bool {
        guard let city = currentCity else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: city.timezone) ?? .current
        return calendar.component(.weekday, from: Date()) == 6
    }
}

extension Date {
    /// "HH:mm" — vakit saat gösterimi.
    var hhmm: String {
        Self.hhmmFormatter.string(from: self)
    }

    private static let hhmmFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

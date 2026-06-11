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
    var dailyContent: DailyContentEntry
    var isLoading: Bool = false
    var currentCity: City?
    var needsOnboarding: Bool = false

    private let storage: StorageService
    private let prayerService: PrayerTimeService
    private var language: String

    init(
        storage: StorageService = .shared,
        prayerService: PrayerTimeService = .shared
    ) {
        self.storage = storage
        self.prayerService = prayerService
        self.language = storage.language
        self.dailyContent = DailyContent.today()

        if let snapshot = storage.selectedCity {
            currentCity = snapshot.makeCity()
        } else {
            needsOnboarding = true
        }
    }

    /// Bugün + yarın vakitlerini yükler, sonraki 7 günü cache'e doldurur.
    func load() async {
        language = storage.language
        dailyContent = DailyContent.today()

        guard let city = currentCity ?? storage.selectedCity.map({ $0.makeCity() }) else {
            needsOnboarding = true
            return
        }
        currentCity = city
        needsOnboarding = false
        isLoading = true
        defer { isLoading = false }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

        async let todayTask = prayerService.getPrayerTimes(city: city, date: today)
        async let tomorrowTask = prayerService.getPrayerTimes(city: city, date: tomorrow)
        let (todayTimes, tomorrowTimes) = await (todayTask, tomorrowTask)

        todaysTimes = todayTimes
        tomorrowsTimes = tomorrowTimes
        hijriDate = "\(todayTimes.hijriDay) \(todayTimes.hijriMonthName) \(todayTimes.hijriYear)"
        tick(date: Date())

        // Kalan günleri arka planda cache'le (UI'ı bekletme).
        Task { await prayerService.prefetch(city: city) }
    }

    /// Her saniye View'dan (TimelineView) çağrılır: geri sayımı ve sıradaki vakti günceller.
    func tick(date: Date) {
        guard let today = todaysTimes else { return }

        // Gün değiştiyse (gece yarısı) verileri yeniden yükle.
        if Calendar.current.startOfDay(for: date) != today.date, !isLoading {
            Task { await load() }
            return
        }

        let next = prayerService.nextPrayer(from: today, tomorrow: tomorrowsTimes, at: date)
        nextPrayer = next.prayer
        nextPrayerTime = next.time
        countdownString = Self.countdownString(
            until: next.time,
            from: date,
            language: language
        )
    }

    /// Geçerli dile göre geri sayım metni.
    /// TR: "2s 34dk sonra" / "34dk sonra" / "Az kaldı"
    /// EN: "in 2h 34m" / "in 34m" / "Almost time"
    static func countdownString(until target: Date, from now: Date, language: String) -> String {
        let interval = max(0, target.timeIntervalSince(now))
        let isTurkish = language == "tr"

        if interval < 60 {
            return isTurkish ? "Az kaldı" : "Almost time"
        }

        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return isTurkish ? "\(minutes)dk sonra" : "in \(minutes)m"
        }
        return isTurkish ? "\(hours)s \(minutes)dk sonra" : "in \(hours)h \(minutes)m"
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
}

// MARK: - Geçici lokalizasyon yardımcıları
// Phase 3'te String Catalog (Localizable.xcstrings) bunların yerini alacak.

extension Prayer {
    var localizedName: String {
        let isTurkish = StorageService.shared.language == "tr"
        switch self {
        case .fajr: return isTurkish ? "Sabah" : "Fajr"
        case .sunrise: return isTurkish ? "Güneş" : "Sunrise"
        case .dhuhr: return isTurkish ? "Öğle" : "Dhuhr"
        case .asr: return isTurkish ? "İkindi" : "Asr"
        case .maghrib: return isTurkish ? "Akşam" : "Maghrib"
        case .isha: return isTurkish ? "Yatsı" : "Isha"
        }
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

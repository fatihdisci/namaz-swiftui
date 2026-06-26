import Foundation
import WidgetKit

/// Ana uygulamadan App Group'a widget snapshot'ı yazan tek nokta.
/// Snapshot yazıldıktan sonra widget timeline'ları yeniden yüklenir.
///
/// Çağrıldığı yerler:
///  - HomeViewModel.load() (vakitler yüklendiğinde)
///  - NotificationService.reschedule() (vakitler API/cache'ten tazelendiğinde:
///    açılış, onboarding sonu, şehir/metod/mezhep değişimi)
///  - VakitApp scenePhase .active (foreground)
enum WidgetSnapshotWriter {
    /// Taze hesaplanmış vakitlerden snapshot üretir, yazar ve widget'ı yeniler.
    @MainActor
    static func update(
        city: City,
        today: PrayerTimes,
        tomorrow: PrayerTimes?,
        language: String,
        storage: StorageService = .shared
    ) {
        var days = [today]
        if let tomorrow { days.append(tomorrow) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: city.timezone) ?? .current
        let todayDate = today.date
        for offset in 2..<Self.snapshotDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: todayDate),
                  let cached = storage.cachedPrayerTimes(for: date, timeZone: calendar.timeZone)?.times
            else { continue }
            days.append(cached)
        }

        save(city: city, days: days, language: language)
    }

    @MainActor
    static func update(city: City, days: [PrayerTimes], language: String) {
        save(city: city, days: days, language: language)
    }

    private static let snapshotDays = 30

    @MainActor
    private static func save(city: City, days rawDays: [PrayerTimes], language: String) {
        let sortedDays = rawDays.sorted { $0.date < $1.date }
        guard let firstDay = sortedDays.first else { return }
        let widgetDays = sortedDays.map(Self.day(from:))
        let rows = widgetDays.first?.rows ?? []
        let tomorrowRows = widgetDays.dropFirst().first?.rows ?? []

        let now = Date()
        let accentKey = sortedDays
            .flatMap { day in Prayer.allCases.map { ($0, day.time(for: $0)) } }
            .first { $0.1 > now }?.0.rawValue
            ?? Prayer.fajr.rawValue

        // Widget Medium için günlük değişen içerik (Hook Model variable reward)
        let verse = DailyContent.dailyVerse()
        let hadith = DailyContent.dailyHadith()
        let dailyText: String?
        let dailyRef: String?
        if let verse {
            dailyText = verse.text(language: language)
            dailyRef = verse.reference
        } else if let hadith {
            dailyText = hadith.text(language: language)
            dailyRef = hadith.source
        } else {
            dailyText = nil
            dailyRef = nil
        }

        let snapshot = WidgetPrayerSnapshot(
            cityName: city.name,
            shortCityName: Self.shortName(from: city.name),
            countryName: city.country,
            date: firstDay.date,
            hijriDate: Self.hijriDate(from: firstDay),
            rows: rows,
            tomorrowRows: tomorrowRows,
            days: widgetDays,
            tomorrowFajr: sortedDays.dropFirst().first?.fajr,
            language: language,
            accentPrayerKey: accentKey,
            dailyVerseText: dailyText,
            dailyVerseReference: dailyRef
        )

        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()

        #if DEBUG
        print("[Widget] snapshot yazıldı: \(snapshot.shortCityName), sıradaki=\(accentKey), gün=\(widgetDays.count)")
        #endif
    }

    /// Foreground gibi vakit hesaplaması yapılmayan durumlar için: cache'ten okuyup yazar.
    @MainActor
    static func refreshFromCache(storage: StorageService = .shared, language: String) {
        guard let city = storage.resolvedCity else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: city.timezone) ?? .current
        let today = calendar.startOfDay(for: Date())
        var days: [PrayerTimes] = []
        for offset in 0..<Self.snapshotDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today),
                  let cached = storage.cachedPrayerTimes(for: date, timeZone: calendar.timeZone)?.times
            else { continue }
            days.append(cached)
        }
        guard !days.isEmpty else { return }
        update(city: city, days: days, language: language)
    }

    private static func day(from times: PrayerTimes) -> WidgetPrayerSnapshot.Day {
        WidgetPrayerSnapshot.Day(
            date: times.date,
            hijriDate: Self.hijriDate(from: times),
            rows: rows(from: times)
        )
    }

    private static func hijriDate(from times: PrayerTimes) -> String {
        "\(times.hijriDay) \(times.hijriMonthName.hijriDiacriticStripped) \(times.hijriYear)"
    }

    private static func rows(from times: PrayerTimes) -> [WidgetPrayerSnapshot.Row] {
        Prayer.allCases.map {
            WidgetPrayerSnapshot.Row(prayerKey: $0.rawValue, time: times.time(for: $0))
        }
    }

    /// "Kadıköy, İstanbul" → "Kadıköy". Virgül yoksa adın kendisi.
    private static func shortName(from name: String) -> String {
        name.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? name
    }
}

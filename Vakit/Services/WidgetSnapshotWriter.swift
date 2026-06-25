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
    static func update(city: City, today: PrayerTimes, tomorrow: PrayerTimes?, language: String) {
        let rows = Self.rows(from: today)
        let tomorrowRows = tomorrow.map(Self.rows(from:)) ?? []

        let now = Date()
        let accentKey = Prayer.allCases.first { today.time(for: $0) > now }?.rawValue
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
            date: today.date,
            hijriDate: "\(today.hijriDay) \(today.hijriMonthName.hijriDiacriticStripped) \(today.hijriYear)",
            rows: rows,
            tomorrowRows: tomorrowRows,
            tomorrowFajr: tomorrow?.fajr,
            language: language,
            accentPrayerKey: accentKey,
            dailyVerseText: dailyText,
            dailyVerseReference: dailyRef
        )

        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()

        #if DEBUG
        print("[Widget] snapshot yazıldı: \(snapshot.shortCityName), sıradaki=\(accentKey), satır=\(rows.count)")
        #endif
    }

    /// Foreground gibi vakit hesaplaması yapılmayan durumlar için: cache'ten okuyup yazar.
    @MainActor
    static func refreshFromCache(storage: StorageService = .shared, language: String) {
        guard let city = storage.resolvedCity else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: city.timezone) ?? .current
        let today = calendar.startOfDay(for: Date())
        guard let cachedToday = storage.cachedPrayerTimes(for: today, timeZone: calendar.timeZone)?.times else { return }
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: today)
        let cachedTomorrow = tomorrowDate.flatMap {
            storage.cachedPrayerTimes(for: $0, timeZone: calendar.timeZone)?.times
        }
        update(city: city, today: cachedToday, tomorrow: cachedTomorrow, language: language)
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

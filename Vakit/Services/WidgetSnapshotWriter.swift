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
    static func update(city: City, today: PrayerTimes, tomorrow: PrayerTimes?, language: String) {
        let rows = Prayer.allCases.map {
            WidgetPrayerSnapshot.Row(prayerKey: $0.rawValue, time: today.time(for: $0))
        }

        let now = Date()
        let accentKey = Prayer.allCases.first { today.time(for: $0) > now }?.rawValue
            ?? Prayer.fajr.rawValue

        let snapshot = WidgetPrayerSnapshot(
            cityName: city.name,
            shortCityName: Self.shortName(from: city.name),
            countryName: city.country,
            date: today.date,
            hijriDate: "\(today.hijriDay) \(today.hijriMonthName) \(today.hijriYear)",
            rows: rows,
            tomorrowFajr: tomorrow?.fajr,
            language: language,
            accentPrayerKey: accentKey
        )

        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()

        #if DEBUG
        print("[Widget] snapshot yazıldı: \(snapshot.shortCityName), sıradaki=\(accentKey), satır=\(rows.count)")
        #endif
    }

    /// Foreground gibi vakit hesaplaması yapılmayan durumlar için: cache'ten okuyup yazar.
    static func refreshFromCache(storage: StorageService = .shared, language: String) {
        guard let city = storage.resolvedCity else { return }
        let today = Calendar.current.startOfDay(for: Date())
        guard let cachedToday = storage.cachedPrayerTimes(for: today)?.times else { return }
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: today)
        let cachedTomorrow = tomorrowDate.flatMap { storage.cachedPrayerTimes(for: $0)?.times }
        update(city: city, today: cachedToday, tomorrow: cachedTomorrow, language: language)
    }

    /// "Kadıköy, İstanbul" → "Kadıköy". Virgül yoksa adın kendisi.
    private static func shortName(from name: String) -> String {
        name.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? name
    }
}

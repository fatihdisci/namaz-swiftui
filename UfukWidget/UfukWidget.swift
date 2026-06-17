import WidgetKit
import SwiftUI

// MARK: - Tema (widget'a özel, sade teal aksan — ana app moruna bağlı değil)

private enum WidgetTheme {
    static let bg      = Color(red: 0.039, green: 0.039, blue: 0.059) // #0a0a0f
    static let surface = Color(red: 0.082, green: 0.086, blue: 0.110) // #15161c
    static let text    = Color(red: 0.945, green: 0.941, blue: 0.929) // #f1f0ed
    static let dim     = Color(red: 0.55, green: 0.56, blue: 0.55)    // okunaklı gri
    static let accent  = Color(red: 0.13, green: 0.66, blue: 0.53)    // sakin teal-yeşil
    static let border  = Color.white.opacity(0.08)
}

// MARK: - Lokalizasyon (snapshot dili → metin)

private enum WidgetText {
    private static let prayerTR: [String: String] = [
        "fajr": "İmsak", "sunrise": "Güneş", "dhuhr": "Öğle",
        "asr": "İkindi", "maghrib": "Akşam", "isha": "Yatsı",
    ]
    private static let prayerEN: [String: String] = [
        "fajr": "Fajr", "sunrise": "Sunrise", "dhuhr": "Dhuhr",
        "asr": "Asr", "maghrib": "Maghrib", "isha": "Isha",
    ]

    static func prayerName(_ key: String, _ lang: String) -> String {
        (lang == "tr" ? prayerTR : prayerEN)[key] ?? key
    }

    static func remaining(_ lang: String) -> String {
        lang == "tr" ? "Kalan" : "Remaining"
    }

    static func emptyBody(_ lang: String) -> String {
        lang == "tr" ? "Şehir seçmek için uygulamayı açın." : "Open Ufuk to choose a city."
    }

    /// "2s 14dk" / "2h 14m" — entry zamanında hesaplanır, canlı saniye yok.
    static func countdown(to target: Date, from now: Date, lang: String) -> String {
        let interval = max(0, target.timeIntervalSince(now))
        if interval < 60 {
            return lang == "tr" ? "Az kaldı" : "Almost time"
        }
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            return lang == "tr" ? "\(minutes)dk" : "\(minutes)m"
        }
        return lang == "tr" ? "\(hours)s \(minutes)dk" : "\(hours)h \(minutes)m"
    }

    /// Galeri başlığı/açıklaması cihaz diline göre.
    static var deviceIsTurkish: Bool {
        (Locale.current.language.languageCode?.identifier ?? "en") == "tr"
    }
}

private extension Date {
    var hhmm: String { Date.hhmmFormatter.string(from: self) }
    static let hhmmFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// MARK: - Timeline

struct UfukEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetPrayerSnapshot?
}

struct UfukProvider: TimelineProvider {
    func placeholder(in context: Context) -> UfukEntry {
        UfukEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (UfukEntry) -> Void) {
        let snapshot = context.isPreview ? .sample : WidgetSnapshotStore.load()
        completion(UfukEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UfukEntry>) -> Void) {
        let now = Date()

        guard let snapshot = WidgetSnapshotStore.load() else {
            // Snapshot yoksa boş durum; uygulama açılınca reloadAllTimelines tetikler.
            let entry = UfukEntry(date: now, snapshot: nil)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(30 * 60))))
            return
        }

        // Entry zamanları: 15 dk aralıklı (geri sayım metni tazelensin) +
        // her vaktin tam zamanı (sıradaki vakit tam o anda değişsin).
        var dates: [Date] = [now]
        var cursor = now
        let horizon = now.addingTimeInterval(5 * 60 * 60)
        while cursor < horizon {
            cursor = cursor.addingTimeInterval(15 * 60)
            dates.append(cursor)
        }
        dates.append(contentsOf: snapshot.upcomingTimes(after: now))

        let entryDates = Array(Set(dates)).filter { $0 >= now }.sorted().prefix(64)
        let entries = entryDates.map { UfukEntry(date: $0, snapshot: snapshot) }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Sample (preview / placeholder)

private extension WidgetPrayerSnapshot {
    static var sample: WidgetPrayerSnapshot {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        func t(_ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: start) ?? start
        }
        return WidgetPrayerSnapshot(
            cityName: "Kadıköy, İstanbul",
            shortCityName: "Kadıköy",
            countryName: "Türkiye",
            date: start,
            hijriDate: "12 Ramadan 1447",
            rows: [
                .init(prayerKey: "fajr", time: t(5, 12)),
                .init(prayerKey: "sunrise", time: t(6, 41)),
                .init(prayerKey: "dhuhr", time: t(13, 9)),
                .init(prayerKey: "asr", time: t(16, 48)),
                .init(prayerKey: "maghrib", time: t(19, 26)),
                .init(prayerKey: "isha", time: t(20, 49)),
            ],
            tomorrowFajr: t(5, 11).addingTimeInterval(24 * 3600),
            language: WidgetText.deviceIsTurkish ? "tr" : "en",
            accentPrayerKey: "asr"
        )
    }
}

// MARK: - Views

struct UfukWidgetEntryView: View {
    var entry: UfukEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .systemMedium:
                    MediumView(snapshot: snapshot, now: entry.date)
                default:
                    SmallView(snapshot: snapshot, now: entry.date)
                }
            } else {
                EmptyStateView()
            }
        }
        .containerBackground(WidgetTheme.bg, for: .widget)
    }
}

private struct BrandRow: View {
    let trailing: String
    var body: some View {
        HStack(spacing: 6) {
            Text("Ufuk")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetTheme.accent)
            Spacer(minLength: 4)
            Text(trailing)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WidgetTheme.dim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct SmallView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        let next = snapshot.next(after: now)

        VStack(alignment: .leading, spacing: 0) {
            BrandRow(trailing: snapshot.shortCityName)

            Spacer(minLength: 6)

            if let next {
                Text(WidgetText.prayerName(next.key, snapshot.language))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(WidgetTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(next.time.hhmm)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                HStack(spacing: 4) {
                    Text(WidgetText.remaining(snapshot.language))
                        .foregroundStyle(WidgetTheme.dim)
                    Text(WidgetText.countdown(to: next.time, from: now, lang: snapshot.language))
                        .foregroundStyle(WidgetTheme.text)
                }
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            } else {
                Text("—")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.dim)
            }
        }
    }
}

private struct MediumView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        let next = snapshot.next(after: now)

        HStack(spacing: 14) {
            // Sol: sıradaki vakit + geri sayım
            VStack(alignment: .leading, spacing: 0) {
                BrandRow(trailing: snapshot.shortCityName)

                Spacer(minLength: 6)

                if let next {
                    Text(WidgetText.prayerName(next.key, snapshot.language))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WidgetTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(next.time.hhmm)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    HStack(spacing: 4) {
                        Text(WidgetText.remaining(snapshot.language))
                            .foregroundStyle(WidgetTheme.dim)
                        Text(WidgetText.countdown(to: next.time, from: now, lang: snapshot.language))
                            .foregroundStyle(WidgetTheme.text)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                Text(snapshot.hijriDate.hijriDiacriticStripped)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetTheme.dim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Sağ: bugünkü vakitler kompakt liste
            VStack(spacing: 0) {
                ForEach(snapshot.rows, id: \.prayerKey) { row in
                    let isNext = next?.key == row.prayerKey && next?.time == row.time
                    let isPast = row.time <= now
                    HStack {
                        Text(WidgetText.prayerName(row.prayerKey, snapshot.language))
                            .foregroundStyle(isNext ? WidgetTheme.accent : WidgetTheme.text)
                        Spacer(minLength: 6)
                        Text(row.time.hhmm)
                            .foregroundStyle(isNext ? WidgetTheme.accent : WidgetTheme.text)
                            .monospacedDigit()
                    }
                    .font(.system(size: 12, weight: isNext ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .opacity(isPast && !isNext ? 0.45 : 1)
                    .padding(.vertical, 2.5)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(WidgetTheme.surface)
            )
            .frame(width: 150)
        }
    }
}

private struct EmptyStateView: View {
    private var lang: String { WidgetText.deviceIsTurkish ? "tr" : "en" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ufuk")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetTheme.accent)
            Spacer(minLength: 0)
            Text(WidgetText.emptyBody(lang))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WidgetTheme.text)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct UfukWidget: Widget {
    let kind = "UfukWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UfukProvider()) { entry in
            UfukWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WidgetText.deviceIsTurkish ? "Namaz Vakitleri" : "Prayer Times")
        .description(
            WidgetText.deviceIsTurkish
                ? "Sıradaki namaz vaktini ve kalan süreyi gösterir."
                : "Shows the next prayer time and the time remaining."
        )
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct UfukWidgetBundle: WidgetBundle {
    var body: some Widget {
        UfukWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    UfukWidget()
} timeline: {
    UfukEntry(date: Date(), snapshot: .sample)
    UfukEntry(date: Date(), snapshot: nil)
}

#Preview(as: .systemMedium) {
    UfukWidget()
} timeline: {
    UfukEntry(date: Date(), snapshot: .sample)
}

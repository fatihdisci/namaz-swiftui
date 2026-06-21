import WidgetKit
import SwiftUI

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

// MARK: - Vakit penceresi (progress halkası için)

private extension WidgetPrayerSnapshot {
    /// Verilen andaki "önceki → sonraki" vakit penceresi.
    /// Progress halkası bu aralık üzerinden dolar.
    func window(at now: Date) -> (previous: Date, next: (key: String, time: Date))? {
        guard let next = next(after: now) else { return nil }
        let sorted = rows.sorted { $0.time < $1.time }

        if let previous = sorted.last(where: { $0.time <= now }) {
            return (previous.time, next)
        }
        // Bugünün İmsak'ından önce: önceki sınır ≈ dünün Yatsısı (bugünkü Yatsı − 24s).
        if let isha = rows.first(where: { $0.prayerKey == "isha" }) {
            return (isha.time.addingTimeInterval(-24 * 3600), next)
        }
        return (now.addingTimeInterval(-3600), next)
    }

    /// 0...1 dolum oranı.
    func progress(at now: Date) -> Double {
        guard let window = window(at: now) else { return 0 }
        let total = window.next.time.timeIntervalSince(window.previous)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(window.previous) / total))
    }
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

        // Entry zamanları: 15 dk aralıklı (geri sayım metni + halka tazelensin) +
        // her vaktin tam zamanı (sıradaki vakit ve gökyüzü fazı tam o anda değişsin).
        // Canlı saniye sayımı kilit ekranında Text/ProgressView(timerInterval:) ile,
        // sistem tarafından reload'sız yapılır.
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

// MARK: - Entry View (aile yönlendirmesi)

struct UfukWidgetEntryView: View {
    var entry: UfukEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(for: .widget) {
                background
            }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                MediumView(snapshot: snapshot, now: entry.date)
            case .accessoryCircular:
                CircularAccessoryView(snapshot: snapshot, now: entry.date)
            case .accessoryRectangular:
                RectangularAccessoryView(snapshot: snapshot, now: entry.date)
            case .accessoryInline:
                InlineAccessoryView(snapshot: snapshot, now: entry.date)
            default:
                SmallView(snapshot: snapshot, now: entry.date)
            }
        } else {
            EmptyStateView(family: family)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch family {
        case .systemSmall, .systemMedium:
            if let snapshot = entry.snapshot {
                currentSkyPhase(now: entry.date, snapshot: snapshot).gradient
            } else {
                Color(rgbHex: 0x0a0a1a)
            }
        case .accessoryCircular, .accessoryRectangular:
            AccessoryWidgetBackground()
        default:
            Color.clear
        }
    }
}

// MARK: - Ortak parçalar

private struct BrandRow: View {
    let trailing: String
    let phase: SkyPhase
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Ufuk")
                .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.cream)
            Spacer(minLength: 4)
            Text(trailing)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WidgetPalette.creamFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .skyTextShadow(phase)
    }
}

private extension View {
    /// Açık gökyüzü fazlarında metni okunur tutmak için hafif gölge.
    @ViewBuilder
    func skyTextShadow(_ phase: SkyPhase) -> some View {
        if phase.needsTextShadow {
            shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        } else {
            self
        }
    }
}

// MARK: - systemSmall

private struct SmallView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        let phase = currentSkyPhase(now: now, snapshot: snapshot)
        let next = snapshot.next(after: now)
        let progress = snapshot.progress(at: now)

        VStack(spacing: 6) {
            BrandRow(trailing: snapshot.shortCityName, phase: phase)

            if let next {
                PrayerProgressRing(
                    progress: progress,
                    nextPrayerKey: next.key,
                    lineWidth: 6,
                    iconSize: 20
                )
                .frame(width: 58, height: 58)

                VStack(spacing: 1) {
                    Text(WidgetText.prayerName(next.key, snapshot.language))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(WidgetPalette.creamDim)

                    Text(next.time.hhmm)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    HStack(spacing: 3) {
                        Text(WidgetText.remaining(snapshot.language))
                        Text(WidgetText.countdown(to: next.time, from: now, lang: snapshot.language))
                    }
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.creamFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            } else {
                Spacer()
                Text("—")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.creamFaint)
                Spacer()
            }
        }
        .skyTextShadow(phase)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - systemMedium

private struct MediumView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        let phase = currentSkyPhase(now: now, snapshot: snapshot)
        let next = snapshot.next(after: now)
        let progress = snapshot.progress(at: now)

        HStack(spacing: 14) {
            // SOL: marka + şehir + halka + sonraki vakit/saat + hicri
            VStack(alignment: .leading, spacing: 6) {
                BrandRow(trailing: snapshot.shortCityName, phase: phase)

                Spacer(minLength: 0)

                if let next {
                    HStack(spacing: 10) {
                        PrayerProgressRing(
                            progress: progress,
                            nextPrayerKey: next.key,
                            lineWidth: 5,
                            iconSize: 16
                        )
                        .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(WidgetText.prayerName(next.key, snapshot.language))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(WidgetPalette.creamDim)
                            Text(next.time.hhmm)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(WidgetPalette.cream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }

                    HStack(spacing: 3) {
                        Text(WidgetText.remaining(snapshot.language))
                        Text(WidgetText.countdown(to: next.time, from: now, lang: snapshot.language))
                    }
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.creamFaint)
                }

                Spacer(minLength: 0)

                Text(snapshot.hijriDate.hijriDiacriticStripped)
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.creamFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .skyTextShadow(phase)

            // SAĞ: 6 vakit listesi, sıradaki vakit altın vurgulu
            VStack(spacing: 0) {
                ForEach(snapshot.rows, id: \.prayerKey) { row in
                    let isNext = next?.key == row.prayerKey && next?.time == row.time
                    let isPast = row.time <= now
                    HStack(spacing: 6) {
                        PrayerIconView(
                            prayerKey: row.prayerKey,
                            size: 11,
                            color: isNext ? WidgetPalette.accentGold : WidgetPalette.creamDim
                        )
                        .frame(width: 14)
                        Text(WidgetText.prayerName(row.prayerKey, snapshot.language))
                            .foregroundStyle(isNext ? WidgetPalette.accentGold : WidgetPalette.cream)
                        Spacer(minLength: 4)
                        Text(row.time.hhmm)
                            .foregroundStyle(isNext ? WidgetPalette.accentGold : WidgetPalette.cream)
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
                    .fill(.black.opacity(0.18))
            )
            .frame(width: 150)
        }
    }
}

// MARK: - accessoryCircular (kilit ekranı, saat etrafı)

private struct CircularAccessoryView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        if let window = snapshot.window(at: now) {
            LivePrayerProgressRing(
                interval: window.previous...window.next.time,
                nextPrayerKey: window.next.key
            )
            .widgetAccentable()
        } else {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 16))
        }
    }
}

// MARK: - accessoryRectangular (kilit ekranı)

private struct RectangularAccessoryView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        let next = snapshot.next(after: now)

        VStack(alignment: .leading, spacing: 2) {
            if let next {
                HStack(spacing: 4) {
                    Image(systemName: PrayerIcon.symbol(for: next.key))
                        .font(.caption)
                        .symbolRenderingMode(.hierarchical)
                        .widgetAccentable()
                    Text("\(WidgetText.prayerName(next.key, snapshot.language)) · \(next.time.hhmm)")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                HStack(spacing: 4) {
                    Text(WidgetText.remaining(snapshot.language))
                    Text(timerInterval: now...next.time, countsDown: true)
                        .monospacedDigit()
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            } else {
                Text(snapshot.shortCityName)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - accessoryInline (kilit ekranı, saat üstü)

private struct InlineAccessoryView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        if let next = snapshot.next(after: now) {
            Label {
                Text("\(WidgetText.prayerName(next.key, snapshot.language)) \(next.time.hhmm)")
            } icon: {
                Image(systemName: PrayerIcon.symbol(for: next.key))
            }
        } else {
            Text("Ufuk")
        }
    }
}

// MARK: - Boş durum

private struct EmptyStateView: View {
    let family: WidgetFamily
    private var lang: String { WidgetText.deviceIsTurkish ? "tr" : "en" }

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("Ufuk")
        case .accessoryCircular:
            Image(systemName: "moon.stars.fill")
        case .accessoryRectangular:
            Text(WidgetText.emptyBody(lang))
                .font(.caption)
                .lineLimit(2)
        default:
            VStack(alignment: .leading, spacing: 8) {
                Text("Ufuk")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.accentGold)
                Spacer(minLength: 0)
                Text(WidgetText.emptyBody(lang))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.cream)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

@main
struct UfukWidgetBundle: WidgetBundle {
    var body: some Widget {
        UfukWidget()
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    UfukWidget()
} timeline: {
    UfukEntry(date: Date(), snapshot: .sample)
    UfukEntry(date: Date(), snapshot: nil)
}

#Preview("Medium", as: .systemMedium) {
    UfukWidget()
} timeline: {
    UfukEntry(date: Date(), snapshot: .sample)
}

#Preview("Circular", as: .accessoryCircular) {
    UfukWidget()
} timeline: {
    UfukEntry(date: Date(), snapshot: .sample)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    UfukWidget()
} timeline: {
    UfukEntry(date: Date(), snapshot: .sample)
}

#Preview("Inline", as: .accessoryInline) {
    UfukWidget()
} timeline: {
    UfukEntry(date: Date(), snapshot: .sample)
}

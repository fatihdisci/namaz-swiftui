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

        // Entry zamanları: 15 dk aralıklı (geri sayım metni + halka tazelensin) +
        // her vaktin tam zamanı (sıradaki vakit ve gökyüzü fazı tam o anda değişsin).
        // Hesap snapshot'taki sabit kalan süreden değil, entry.date/current Date akışından yapılır.
        let entryDates = snapshot.timelineEntryDates(from: now).prefix(96)
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
        let tomorrowOffset: TimeInterval = 24 * 3600
        let todayRows: [WidgetPrayerSnapshot.Row] = [
            .init(prayerKey: "fajr", time: t(5, 12)),
            .init(prayerKey: "sunrise", time: t(6, 41)),
            .init(prayerKey: "dhuhr", time: t(13, 9)),
            .init(prayerKey: "asr", time: t(16, 48)),
            .init(prayerKey: "maghrib", time: t(19, 26)),
            .init(prayerKey: "isha", time: t(20, 49)),
        ]
        let tomorrowRows: [WidgetPrayerSnapshot.Row] = [
            .init(prayerKey: "fajr", time: t(5, 11).addingTimeInterval(tomorrowOffset)),
            .init(prayerKey: "sunrise", time: t(6, 40).addingTimeInterval(tomorrowOffset)),
            .init(prayerKey: "dhuhr", time: t(13, 10).addingTimeInterval(tomorrowOffset)),
            .init(prayerKey: "asr", time: t(16, 49).addingTimeInterval(tomorrowOffset)),
            .init(prayerKey: "maghrib", time: t(19, 27).addingTimeInterval(tomorrowOffset)),
            .init(prayerKey: "isha", time: t(20, 50).addingTimeInterval(tomorrowOffset)),
        ]
        return WidgetPrayerSnapshot(
            cityName: "Kadıköy, İstanbul",
            shortCityName: "Kadıköy",
            countryName: "Türkiye",
            date: start,
            hijriDate: "12 Ramadan 1447",
            rows: todayRows,
            tomorrowRows: tomorrowRows,
            days: [
                .init(date: start, hijriDate: "12 Ramadan 1447", rows: todayRows),
                .init(date: cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(tomorrowOffset), hijriDate: "13 Ramadan 1447", rows: tomorrowRows),
            ],
            tomorrowFajr: tomorrowRows.first?.time,
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
            case .systemLarge:
                LargeView(snapshot: snapshot, now: entry.date)
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
        case .systemSmall, .systemMedium, .systemLarge:
            if let snapshot = entry.snapshot {
                currentSkyPhase(now: entry.date, snapshot: snapshot).gradient
            } else {
                Color(rgbHex: 0x0a0a1a)
            }
        case .accessoryRectangular:
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

        VStack(spacing: 6) {
            BrandRow(trailing: snapshot.shortCityName, phase: phase)

            if let next {
                PrayerIconView(
                    prayerKey: next.key,
                    size: 24,
                    color: WidgetPalette.accentGold
                )

                VStack(spacing: 1) {
                    Text(WidgetText.prayerName(next.key, snapshot.language))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(WidgetPalette.creamDim)
                        .frame(maxWidth: .infinity)

                    Text(next.time.hhmm)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }

                HStack(spacing: 4) {
                    Text(WidgetText.remaining(snapshot.language))
                    Text(timerInterval: now...next.time, countsDown: true)
                        .monospacedDigit()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(WidgetPalette.creamDim)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            } else {
                Spacer()
                Text("—")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.creamDim)
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

        HStack(spacing: 14) {
            // SOL: marka + şehir + ikon + sonraki vakit/saat + hicri
            VStack(alignment: .leading, spacing: 6) {
                BrandRow(trailing: snapshot.shortCityName, phase: phase)

                Spacer(minLength: 0)

                if let next {
                    HStack(spacing: 10) {
                        PrayerIconView(
                            prayerKey: next.key,
                            size: 22,
                            color: WidgetPalette.accentGold
                        )

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

                    HStack(spacing: 4) {
                        Text(WidgetText.remaining(snapshot.language))
                        Text(timerInterval: now...next.time, countsDown: true)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(WidgetPalette.creamDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                Text(snapshot.hijriDate(at: now).hijriDiacriticStripped)
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.creamFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .skyTextShadow(phase)

            // SAĞ: 6 vakit listesi, sıradaki vakit altın vurgulu
            VStack(spacing: 0) {
                ForEach(snapshot.displayRows(at: now), id: \.prayerKey) { row in
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

// MARK: - systemLarge

private struct LargeView: View {
    let snapshot: WidgetPrayerSnapshot
    let now: Date

    var body: some View {
        let phase = currentSkyPhase(now: now, snapshot: snapshot)
        let next = snapshot.next(after: now)

        VStack(spacing: 0) {
            // Üst: marka + şehir
            BrandRow(trailing: snapshot.cityName, phase: phase)
                .padding(.horizontal, 2)
                .padding(.bottom, 14)

            // Orta: sıradaki vakit | vakit listesi (iki sütun)
            HStack(alignment: .top, spacing: 20) {
                // SOL: sıradaki vakit
                VStack(alignment: .leading, spacing: 10) {
                    if let next {
                        HStack(alignment: .center, spacing: 12) {
                            PrayerIconView(
                                prayerKey: next.key,
                                size: 20,
                                color: WidgetPalette.accentGold
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(WidgetText.prayerName(next.key, snapshot.language))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(WidgetPalette.creamDim)
                                Text(next.time.hhmm)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(WidgetPalette.cream)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                        }

                        HStack(spacing: 5) {
                            Image(systemName: "timer")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(WidgetPalette.accentGold.opacity(0.6))
                            Text(WidgetText.remaining(snapshot.language))
                            Text(timerInterval: now...next.time, countsDown: true)
                                .monospacedDigit()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WidgetPalette.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }

                    Spacer(minLength: 6)

                    Text(snapshot.hijriDate(at: now).hijriDiacriticStripped)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetPalette.creamFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .skyTextShadow(phase)

                // SAĞ: 6 vakit listesi
                VStack(spacing: 0) {
                    ForEach(snapshot.displayRows(at: now), id: \.prayerKey) { row in
                        let isNext = next?.key == row.prayerKey && next?.time == row.time
                        let isPast = row.time <= now
                        HStack(spacing: 8) {
                            PrayerIconView(
                                prayerKey: row.prayerKey,
                                size: 12,
                                color: isNext ? WidgetPalette.accentGold : WidgetPalette.creamDim
                            )
                            .frame(width: 16)
                            Text(WidgetText.prayerName(row.prayerKey, snapshot.language))
                                .foregroundStyle(isNext ? WidgetPalette.accentGold : WidgetPalette.cream)
                            Spacer(minLength: 6)
                            Text(row.time.hhmm)
                                .foregroundStyle(isNext ? WidgetPalette.accentGold : WidgetPalette.cream)
                                .monospacedDigit()
                        }
                        .font(.system(size: 13, weight: isNext ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .opacity(isPast && !isNext ? 0.4 : 1)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.black.opacity(0.18))
                )
                .frame(width: 155)
            }

            Spacer(minLength: 12)

            // Alt: günün ayeti/hadisi kartı
            if let verseText = snapshot.dailyVerseText {
                dailyVerseCard(verseText: verseText, reference: snapshot.dailyVerseReference, phase: phase)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }

    // MARK: Daily verse card

    private func dailyVerseCard(verseText: String, reference: String?, phase: SkyPhase) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accentGold.opacity(0.7))
                Text(snapshot.language == "tr" ? "Günün Ayeti" : "Verse of the Day")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accentGold.opacity(0.7))
                    .textCase(.uppercase)
            }

            Text(verseText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WidgetPalette.cream)
                .lineLimit(3)
                .lineSpacing(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)

            if let reference {
                Text("— \(reference)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(WidgetPalette.creamFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WidgetPalette.accentGold.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(WidgetPalette.accentGold.opacity(0.12), lineWidth: 1)
        )
        .skyTextShadow(phase)
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
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
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
            .systemLarge,
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

#Preview("Large", as: .systemLarge) {
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

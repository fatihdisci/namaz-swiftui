import SwiftUI

/// Sıradaki vakti gösteren büyük kart: vakit adı, saat, canlı geri sayım ve gün içi ilerleme.
struct NextPrayerCard: View {
    let prayer: Prayer
    let time: Date
    let countdown: String
    let progress: Double

    @Environment(LanguageService.self) private var lang

    private var clampedProgress: Double {
        guard progress.isFinite else { return 0 }
        return min(1, max(0, progress))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: prayer.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(prayer.accentColor)
                Text(lang.t(prayer.localizationKey))
                    .font(.system(.headline, design: .default, weight: .medium))
                    .foregroundStyle(Color.vakitTextDim)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(time.hhmm)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(countdown)
                    .font(.vakitCountdown)
                    .foregroundStyle(Color.vakitText)
                    .minimumScaleFactor(0.56)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .accessibilityLabel(lang.t("home.nextPrayer.countdown.accessibility", countdown))

                Text(lang.t(prayer.contextLocalizationKey))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            ProgressView(value: clampedProgress)
                .tint(prayer.accentColor)
                .background(Color.white.opacity(0.08), in: Capsule())
                .clipShape(Capsule())
                .accessibilityLabel(lang.t("home.nextPrayer.progress.accessibility"))
                .accessibilityValue("\(Int(clampedProgress * 100))%")
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(prayer.accentColor.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: prayer.accentColor.opacity(0.18), radius: 24, y: 12)
        .accessibilityElement(children: .combine)
    }

    private var cardBackground: some View {
        ZStack(alignment: .topLeading) {
            Color.vakitSurface
            LinearGradient(
                colors: [prayer.accentColor.opacity(0.24), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [prayer.accentColor.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 180
            )
        }
    }
}

private extension Prayer {
    var contextLocalizationKey: String {
        switch self {
        case .fajr: return "home.nextPrayer.context.fajr"
        case .sunrise: return "home.nextPrayer.context.sunrise"
        case .dhuhr: return "home.nextPrayer.context.dhuhr"
        case .asr: return "home.nextPrayer.context.asr"
        case .maghrib: return "home.nextPrayer.context.maghrib"
        case .isha: return "home.nextPrayer.context.isha"
        }
    }
}

#Preview {
    NextPrayerCard(prayer: .maghrib, time: Date(), countdown: "2s 34dk sonra", progress: 0.62)
        .padding()
        .background(Color.vakitBg)
        .environment(LanguageService.shared)
}

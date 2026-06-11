import SwiftUI

/// Sıradaki vakti gösteren büyük kart: vakit adı, saat ve canlı geri sayım.
struct NextPrayerCard: View {
    let prayer: Prayer
    let time: Date
    let countdown: String

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: prayer.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(prayer.accentColor)
                Text(lang.t(prayer.localizationKey))
                    .font(.system(.headline, design: .default, weight: .medium))
                    .foregroundStyle(Color.vakitTextDim)
                Spacer()
                Text(time.hhmm)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
            }

            Text(countdown)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vakitText)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color.vakitSurface
                LinearGradient(
                    colors: [prayer.accentColor.opacity(0.25), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }
}

#Preview {
    NextPrayerCard(prayer: .maghrib, time: Date(), countdown: "2s 34dk sonra")
        .padding()
        .background(Color.vakitBg)
        .environment(LanguageService.shared)
}

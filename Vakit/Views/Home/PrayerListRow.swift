import SwiftUI

/// Vakit listesi satırı: ikon + vakit adı + saat.
/// Geçmiş vakitler soluk, sıradaki vakit aksan rengiyle vurgulu.
struct PrayerListRow: View {
    let prayer: Prayer
    let time: Date
    let isPast: Bool
    let isNext: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isNext ? prayer.accentColor : Color.vakitTextDim)
                .frame(width: 28)

            Text(prayer.localizedName)
                .font(.system(.body, design: .default, weight: isNext ? .semibold : .medium))
                .foregroundStyle(isNext ? prayer.accentColor : Color.vakitText)

            Spacer()

            Text(time.hhmm)
                .font(.system(.body, design: .rounded, weight: isNext ? .semibold : .regular))
                .foregroundStyle(isNext ? prayer.accentColor : Color.vakitText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isNext ? prayer.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isNext ? prayer.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .opacity(isPast ? 0.4 : 1)
    }
}

#Preview {
    VStack(spacing: 4) {
        PrayerListRow(prayer: .fajr, time: Date(), isPast: true, isNext: false)
        PrayerListRow(prayer: .dhuhr, time: Date(), isPast: false, isNext: true)
        PrayerListRow(prayer: .isha, time: Date(), isPast: false, isNext: false)
    }
    .padding()
    .background(Color.vakitBg)
}

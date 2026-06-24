import SwiftUI

struct FridayCard: View {
    let dhuhrTime: Date
    @Environment(LanguageService.self) private var lang

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.vakitAccent.opacity(0.14)))
            VStack(alignment: .leading, spacing: 3) {
                Text(lang.t("friday.title"))
                    .font(.vakitHeadline)
                    .foregroundStyle(Color.vakitText)
                Text(lang.t("friday.subtitle"))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
            }
            Spacer()
            Text(dhuhrTime.hhmm)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vakitAccent)
        }
        .padding(16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.vakitBorder))
    }
}

struct RamadanCard: View {
    let times: PrayerTimes
    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(lang.t("ramadan.title"), systemImage: "moon.stars.fill")
                .font(.vakitHeadline)
                .foregroundStyle(Color.vakitAccent)
            HStack(spacing: 12) {
                timeItem(title: lang.t("ramadan.sahur"), time: times.fajr)
                timeItem(title: lang.t("ramadan.iftar"), time: times.maghrib)
            }
        }
        .padding(16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.vakitBorder))
    }

    private func timeItem(title: String, time: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.vakitReference).foregroundStyle(Color.vakitTextDim)
            Text(time.hhmm)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vakitText)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.vakitAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

import SwiftUI

/// Keşfet: Günün Ayeti + Hadisi + Duası + Esmaül Hüsna.
/// İçerik tamamen offline (bundle JSON); gün seed'i: yılın günü mod içerik sayısı.
struct DiscoverView: View {
    @Environment(LanguageService.self) private var lang

    private let verse = DailyContent.dailyVerse()
    private let hadith = DailyContent.dailyHadith()
    private let dua = DailyContent.dailyDua()
    private let dailyEsma = DailyContent.dailyEsma()
    private let allEsma = DailyContent.esma

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .vakitAccent)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if let verse {
                        verseCard(verse)
                    }
                    if let hadith {
                        hadithCard(hadith)
                    }
                    if let dua {
                        duaCard(dua)
                    }
                    if let dailyEsma {
                        esmaCard(dailyEsma)
                    }
                    if !allEsma.isEmpty {
                        esmaList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lang.t("discover.title"))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vakitText)
            Text(lang.t("discover.subtitle"))
                .font(.subheadline)
                .foregroundStyle(Color.vakitTextDim)
        }
    }

    // MARK: - Kartlar

    private func verseCard(_ verse: Verse) -> some View {
        section(titleKey: "discover.verse", icon: "book.fill", tint: .vakitAccent) {
            VStack(alignment: .leading, spacing: 12) {
                if let arabic = verse.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.vakitText)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }

                Text(verse.text(language: lang.currentLanguage))
                    .font(.system(.body, design: .default))
                    .foregroundStyle(Color.vakitText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                referenceRow(verse.reference)
            }
        }
    }

    private func hadithCard(_ hadith: Hadith) -> some View {
        section(titleKey: "discover.hadith", icon: "text.quote", tint: .sunrise) {
            VStack(alignment: .leading, spacing: 12) {
                Text(hadith.text(language: lang.currentLanguage))
                    .font(.system(.body, design: .default))
                    .foregroundStyle(Color.vakitText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                referenceRow(hadith.source, badge: hadith.grade)
            }
        }
    }

    private func duaCard(_ dua: Dua) -> some View {
        section(titleKey: "discover.dua", icon: "hands.and.sparkles.fill", tint: .isha) {
            VStack(alignment: .leading, spacing: 12) {
                if let arabic = dua.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.vakitText)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }

                Text(dua.text(language: lang.currentLanguage))
                    .font(.system(.body, design: .default))
                    .italic()
                    .foregroundStyle(Color.vakitText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                referenceRow(dua.source, badge: dua.grade)
            }
        }
    }

    private func esmaCard(_ esma: EsmaName) -> some View {
        section(titleKey: "discover.esma", icon: "sparkles", tint: .fajr) {
            VStack(spacing: 6) {
                Text(esma.name(language: lang.currentLanguage))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.vakitAccent)
                Text(esma.meaning(language: lang.currentLanguage))
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var esmaList: some View {
        section(titleKey: "discover.allEsma", icon: "list.bullet", tint: .fajr) {
            VStack(spacing: 0) {
                ForEach(allEsma) { esma in
                    HStack(spacing: 12) {
                        Text("\(esma.number)")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.vakitAccent)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.vakitAccent.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(esma.name(language: lang.currentLanguage))
                                .font(.system(.subheadline, design: .default, weight: .semibold))
                                .foregroundStyle(Color.vakitText)
                            Text(esma.meaning(language: lang.currentLanguage))
                                .font(.caption)
                                .foregroundStyle(Color.vakitTextDim)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    if esma.id != allEsma.last?.id {
                        Divider().overlay(Color.vakitBorder)
                    }
                }
            }
        }
    }

    // MARK: - Yardımcılar

    private func section(
        titleKey: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint.opacity(0.12)))

                Text(lang.t(titleKey))
                    .font(.system(.headline, design: .default, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
            }

            content()
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vakitSurface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.vakitBorder, lineWidth: 1)
                )
        }
    }

    private func referenceRow(_ source: String, badge: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "bookmark")
                .font(.system(size: 11))
                .foregroundStyle(Color.vakitTextDim)

            Text(source)
                .font(.caption)
                .foregroundStyle(Color.vakitTextDim)

            Spacer()

            if let badge, !badge.isEmpty {
                Text(badge)
                    .font(.system(.caption2, design: .default, weight: .bold))
                    .foregroundStyle(Color.vakitAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.vakitAccent.opacity(0.12)))
            }
        }
    }
}

#Preview {
    DiscoverView()
        .environment(LanguageService.shared)
        .preferredColorScheme(.dark)
}

import SwiftUI

/// Keşfet: Günün Ayeti + Hadisi + Duası + Esmaül Hüsna.
/// İçerik tamamen offline (bundle JSON); gün seed'i: yılın günü mod içerik sayısı.
/// Her başlığın yanında kendi PNG arka planlı paylaş butonu bulunur.
struct DiscoverView: View {
    @Environment(LanguageService.self) private var lang

    enum GeneratingType { case verse, hadith, dua }
    @State private var generating: GeneratingType?

    private let verse = DailyContent.dailyVerse()
    private let hadith = DailyContent.dailyHadith()
    private let dua = DailyContent.dailyDua()
    private let dailyEsma = DailyContent.dailyEsma()

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .vakitAccent)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    duaLibraryLink

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
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .overlay(alignment: .top) {
            if generating != nil {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color.vakitAccent)
                    Text(lang.t("discover.generatingImage"))
                        .font(.subheadline)
                        .foregroundStyle(Color.vakitTextDim)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, 100)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t("discover.title"))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.vakitText)
                Text(lang.t("discover.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
            }
            Spacer()
        }
    }

    private var duaLibraryLink: some View {
        NavigationLink {
            DuaLibraryView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.isha)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.isha.opacity(0.14)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(lang.t("dua.library.title"))
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.vakitText)
                    Text(lang.t("dua.library.subtitle"))
                        .font(.footnote)
                        .foregroundStyle(Color.vakitTextDim)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(16)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.vakitBorder))
        }
    }

    // MARK: - Kartlar

    private func verseCard(_ verse: Verse) -> some View {
        section(titleKey: "discover.verse", icon: "book.fill", tint: .vakitAccent,
                onShare: { generateVerseShare() })
        {
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
        section(titleKey: "discover.hadith", icon: "text.quote", tint: .sunrise,
                onShare: { generateHadithShare() })
        {
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
        section(titleKey: "discover.dua", icon: "hands.and.sparkles.fill", tint: .isha,
                onShare: { generateDuaShare() })
        {
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

    // MARK: - Paylaşım (3 ayrı buton)

    private func generateVerseShare() {
        guard generating == nil else { return }
        generating = .verse
        let v = verse
        let langCode = lang.currentLanguage

        Task {
            let image = makeVerseShareImage(verse: v, language: langCode)
            presentShare(image)
        }
    }

    private func generateHadithShare() {
        guard generating == nil else { return }
        generating = .hadith
        let h = hadith
        let langCode = lang.currentLanguage

        Task {
            let image = makeHadithShareImage(hadith: h, language: langCode)
            presentShare(image)
        }
    }

    private func generateDuaShare() {
        guard generating == nil else { return }
        generating = .dua
        let d = dua
        let langCode = lang.currentLanguage

        Task {
            let image = makeDuaShareImage(dua: d, language: langCode)
            presentShare(image)
        }
    }

    @MainActor
    private func presentShare(_ image: UIImage?) {
        generating = nil
        guard let image else { return }
        let av = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    // MARK: - Yardımcılar

    private func section(
        titleKey: String,
        icon: String,
        tint: Color,
        onShare: (() -> Void)? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(tint.opacity(0.12))
                    )
                Text(lang.t(titleKey))
                    .font(.system(.headline, design: .default, weight: .semibold))
                    .foregroundStyle(Color.vakitText)

                Spacer()

                if let onShare {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(tint.opacity(0.12))
                            )
                    }
                    .disabled(generating != nil)
                }
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

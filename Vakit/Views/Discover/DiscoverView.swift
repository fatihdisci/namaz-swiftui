import SwiftUI

/// Keşfet: Günün Ayeti + Hadisi + Duası + Esmaül Hüsna.
/// İçerik tamamen offline (bundle JSON); gün seed'i: yılın günü mod içerik sayısı.
/// Her kartta paylaş butonu: görsel üret → native iOS share sheet.
struct DiscoverView: View {
    @Environment(LanguageService.self) private var lang

    @State private var shareState: ShareState?

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
        .confirmationDialog(
            "Paylaşım Boyutu",
            isPresented: Binding(
                get: { shareState?.isChoosingSize == true },
                set: { if !$0 { shareState = nil } }
            )
        ) {
            ForEach(ShareImageSize.allCases) { size in
                Button(size.displayName) {
                    shareState?.selectedSize = size
                    generateAndShare()
                }
            }
            Button("İptal", role: .cancel) {
                shareState = nil
            }
        }
    }

    // MARK: - Header

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
        section(
            titleKey: "discover.verse",
            icon: "book.fill",
            tint: .vakitAccent,
            onShare: { shareState = ShareState(contentType: .verse(verse)) }
        ) {
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
        section(
            titleKey: "discover.hadith",
            icon: "text.quote",
            tint: .sunrise,
            onShare: { shareState = ShareState(contentType: .hadith(hadith)) }
        ) {
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
        section(
            titleKey: "discover.dua",
            icon: "hands.and.sparkles.fill",
            tint: .isha,
            onShare: { shareState = ShareState(contentType: .dua(dua)) }
        ) {
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
        section(
            titleKey: "discover.esma",
            icon: "sparkles",
            tint: .fajr,
            onShare: { shareState = ShareState(contentType: .esma(esma)) }
        ) {
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

    // MARK: - Paylaşım

    private func generateAndShare() {
        guard var state = shareState, let size = state.selectedSize else { return }
        state.isGenerating = true
        shareState = state

        let contentType = state.contentType
        let language = lang.currentLanguage
        let cgSize = size.cgSize

        Task {
            let image = await Task.detached(priority: .userInitiated) {
                await generateShareImage(
                    contentType: contentType,
                    language: language,
                    size: cgSize
                )
            }.value

            await MainActor.run {
                shareState?.isGenerating = false
                if let image {
                    shareState?.generatedImage = image
                    presentShareSheet(image: image)
                }
                shareState = nil
            }
        }
    }

    private func presentShareSheet(image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Yardımcılar

    private func section(
        titleKey: String,
        icon: String,
        tint: Color,
        onShare: @escaping () -> Void,
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

                Spacer()

                // Paylaş butonu
                if let ss = shareState,
                   ss.contentType.matches(titleKey: titleKey),
                   ss.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 30, height: 30)
                } else {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(tint.opacity(0.12))
                            )
                    }
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

// MARK: - Paylaşım State

@Observable
private final class ShareState {
    let contentType: ShareableContentType
    var selectedSize: ShareImageSize?
    var isGenerating = false
    var generatedImage: UIImage?

    var isChoosingSize: Bool {
        selectedSize == nil && !isGenerating
    }

    init(contentType: ShareableContentType) {
        self.contentType = contentType
    }
}

extension ShareableContentType {
    func matches(titleKey: String) -> Bool {
        switch self {
        case .verse:  return titleKey == "discover.verse"
        case .hadith: return titleKey == "discover.hadith"
        case .dua:    return titleKey == "discover.dua"
        case .esma:   return titleKey == "discover.esma"
        }
    }
}

#Preview {
    DiscoverView()
        .environment(LanguageService.shared)
        .preferredColorScheme(.dark)
}

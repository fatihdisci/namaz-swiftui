import SwiftUI

/// Ana ekrandaki günün ayeti teaser'ı. Tam içerik Keşfet sekmesinde;
/// "Keşfet'te gör" ile oraya geçilir.
struct DailyContentCard: View {
    let verse: Verse
    let language: String
    let onOpenDiscover: () -> Void

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.vakitAccent)

                Text(lang.t("discover.verse"))
                    .font(.system(.footnote, design: .default, weight: .medium))
                    .foregroundStyle(Color.vakitTextDim)
            }

            Text(verse.text(language: language))
                .font(.system(.body, design: .default))
                .foregroundStyle(Color.vakitText)
                .lineSpacing(4)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(verse.reference)
                    .font(.system(.footnote, design: .default, weight: .medium))
                    .foregroundStyle(Color.vakitTextDim)

                Spacer()

                Button(action: onOpenDiscover) {
                    HStack(spacing: 4) {
                        Text(lang.t("daily.viewInDiscover"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.system(.footnote, design: .default, weight: .semibold))
                    .foregroundStyle(Color.vakitAccent)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }
}

#Preview {
    if let verse = DailyContent.dailyVerse() {
        DailyContentCard(verse: verse, language: "tr", onOpenDiscover: {})
            .padding()
            .background(Color.vakitBg)
            .environment(LanguageService.shared)
    }
}

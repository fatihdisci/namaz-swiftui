import SwiftUI

/// Günün ayet/hadis kartı. Uygulama diline göre TR veya EN metni gösterir.
struct DailyContentCard: View {
    let entry: DailyContentEntry
    let language: String

    private var text: String {
        language == "tr" ? entry.textTR : entry.textEN
    }

    private var source: String {
        language == "tr" ? entry.sourceTR : entry.sourceEN
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.vakitAccent)

            Text(text)
                .font(.system(.body, design: .default))
                .foregroundStyle(Color.vakitText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(source)
                .font(.system(.footnote, design: .default, weight: .medium))
                .foregroundStyle(Color.vakitTextDim)
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
    DailyContentCard(entry: DailyContent.entries[0], language: "tr")
        .padding()
        .background(Color.vakitBg)
}

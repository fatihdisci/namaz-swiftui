import SwiftUI

/// Ana ekrandaki küçük günlük içerik preview kartı. Tam içerik Keşfet sekmesinde okunur.
struct DailyContentCard: View {
    let preview: DailyPreviewContent
    let onOpenDiscover: () -> Void

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: preview.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.vakitAccent)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.vakitAccent.opacity(0.12)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(lang.t("home.dailyPreview.title"))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.vakitText)
                    Text(lang.t(preview.titleKey))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.vakitTextDim)
                        .textCase(.uppercase)
                }

                Spacer(minLength: 8)

                Button(action: onOpenDiscover) {
                    HStack(spacing: 4) {
                        Text(lang.t("home.dailyPreview.cta"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .foregroundStyle(Color.vakitAccent)
                    .lineLimit(1)
                }
                .buttonStyle(.plain)
            }

            Text(preview.text)
                .font(.vakitCaption)
                .foregroundStyle(Color.vakitText)
                .lineSpacing(3)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(preview.reference)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.vakitTextDim)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(lang.t("home.dailyPreview.accessibility"))
    }
}

#Preview {
    DailyContentCard(
        preview: DailyPreviewContent(
            iconName: "book.closed.fill",
            titleKey: "home.dailyPreview.kind.verse",
            text: "Şüphesiz zorlukla beraber bir kolaylık vardır.",
            reference: "İnşirah · 6"
        ),
        onOpenDiscover: {}
    )
    .padding()
    .background(Color.vakitBg)
    .environment(LanguageService.shared)
}

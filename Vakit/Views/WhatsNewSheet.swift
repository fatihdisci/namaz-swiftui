import SwiftUI

struct WhatsNewSheet: View {
    let version: String
    var onDismiss: () -> Void = {}

    @Environment(LanguageService.self) private var lang
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    highlights
                    widgetGuide
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .background(Color.vakitBg)
            .navigationTitle(lang.t("whatsNew.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang.t("common.close")) {
                        close()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            onDismiss()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: lang.t("whatsNew.title"), version))
                .font(.vakitScreenTitle)
                .foregroundStyle(Color.vakitText)
                .fixedSize(horizontal: false, vertical: true)

            Text(lang.t("whatsNew.subtitle"))
                .font(.vakitCaption)
                .foregroundStyle(Color.vakitTextDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var highlights: some View {
        VStack(spacing: 12) {
            WhatsNewRow(
                icon: "speaker.wave.2.fill",
                title: lang.t("whatsNew.tts.title"),
                detail: lang.t("whatsNew.tts.body")
            )
            WhatsNewRow(
                icon: "waveform",
                title: lang.t("whatsNew.reciter.title"),
                detail: lang.t("whatsNew.reciter.body")
            )
            WhatsNewRow(
                icon: "sun.max.fill",
                title: lang.t("whatsNew.asr.title"),
                detail: lang.t("whatsNew.asr.body")
            )
        }
    }

    private var widgetGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.grid.2x2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.vakitBg)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.vakitAccent))

                VStack(alignment: .leading, spacing: 4) {
                    Text(lang.t("whatsNew.widget.title"))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.vakitText)
                    Text(lang.t("whatsNew.widget.body"))
                        .font(.subheadline)
                        .foregroundStyle(Color.vakitTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                WidgetStep(number: "1", text: lang.t("whatsNew.widget.step1"))
                WidgetStep(number: "2", text: lang.t("whatsNew.widget.step2"))
                WidgetStep(number: "3", text: lang.t("whatsNew.widget.step3"))
            }
        }
        .padding(16)
        .background(Color.vakitAccent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.vakitAccent.opacity(0.25), lineWidth: 1)
        )
    }

    private func close() {
        dismiss()
    }
}

private struct WhatsNewRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.vakitAccent.opacity(0.14)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.vakitHeadline)
                    .foregroundStyle(Color.vakitText)
                Text(detail)
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }
}

private struct WidgetStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vakitBg)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.vakitAccent))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.vakitText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    WhatsNewSheet(version: "1.1.0")
        .environment(LanguageService.shared)
}

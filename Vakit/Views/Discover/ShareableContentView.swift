import SwiftUI

// MARK: - Paylaşım Boyutu

enum ShareImageSize: String, CaseIterable, Identifiable {
    case story = "Story (1080×1920)"
    case square = "Kare (1080×1080)"

    var id: String { rawValue }

    var cgSize: CGSize {
        switch self {
        case .story:  return CGSize(width: 1080, height: 1920)
        case .square: return CGSize(width: 1080, height: 1080)
        }
    }

    var displayName: String {
        switch self {
        case .story:  return "Story"
        case .square: return "Kare"
        }
    }
}

// MARK: - İçerik Tipi

enum ShareableContentType {
    case verse(Verse)
    case hadith(Hadith)
    case dua(Dua)
    case esma(EsmaName)

    var tint: Color {
        switch self {
        case .verse:  return .vakitAccent
        case .hadith: return .sunrise
        case .dua:    return .isha
        case .esma:   return .fajr
        }
    }
}

// MARK: - Ana Paylaşım Görseli View'ı

/// Discover içeriğini paylaşılabilir görsel olarak render eden view.
/// `ImageRenderer` ile UIImage'a dönüştürülür.
struct ShareableContentView: View {
    let contentType: ShareableContentType
    let language: String       // "tr" veya "en"

    var body: some View {
        ZStack {
            // Aurora gradient arka plan
            auroraBackground

            // İslami geometrik motif (8 köşeli yıldız pattern)
            IslamicStarPattern()
                .stroke(contentType.tint.opacity(0.06), lineWidth: 1)
                .padding(40)

            // İçerik katmanı
            VStack(spacing: 0) {
                // Üst: wordmark
                wordmark
                    .padding(.top, 60)

                Spacer()

                // Merkez: içerik
                contentArea
                    .padding(.horizontal, 60)

                Spacer()

                // Alt: separatör + watermark
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.vakitAccent.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 80)

                    watermark
                }
                .padding(.bottom, 50)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.vakitBg)
    }

    // MARK: - Arka plan

    private var auroraBackground: some View {
        ZStack {
            Color.vakitBg

            LinearGradient(
                colors: [
                    Color.vakitBg,
                    Color(hex: "#1a0a2e"),
                    Color.vakitBg,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Yumuşak ışık lekeleri
            Circle()
                .fill(contentType.tint.opacity(0.08))
                .frame(width: 500, height: 500)
                .blur(radius: 120)
                .offset(x: -150, y: -200)

            Circle()
                .fill(Color.vakitAccent.opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 150, y: 200)
        }
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        Text("Ufuk")
            .font(.system(size: 28, weight: .semibold, design: .serif))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.vakitAccent, Color.sunrise],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .tracking(4)
    }

    // MARK: - İçerik alanı

    @ViewBuilder
    private var contentArea: some View {
        switch contentType {
        case .verse(let verse):
            verseContent(verse)
        case .hadith(let hadith):
            hadithContent(hadith)
        case .dua(let dua):
            duaContent(dua)
        case .esma(let esma):
            esmaContent(esma)
        }
    }

    // MARK: Ayet

    private func verseContent(_ verse: Verse) -> some View {
        VStack(spacing: 24) {
            if let arabic = verse.arabic, !arabic.isEmpty {
                Text(arabic)
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(Color.vakitText)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            Text("\(verse.surahName) · \(verse.verseNumber)")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.vakitAccent)

            Text(verse.text(language: language))
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color(hex: "#e8e0d0"))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .lineLimit(3)
        }
    }

    // MARK: Hadis

    private func hadithContent(_ hadith: Hadith) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "quote.opening")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.vakitAccent)

            Text(hadith.text(language: language))
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.vakitText)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .lineLimit(5)

            if !hadith.grade.isEmpty {
                Text(hadith.grade)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.vakitAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.vakitAccent.opacity(0.12))
                    )
            }
        }
    }

    // MARK: Dua

    private func duaContent(_ dua: Dua) -> some View {
        VStack(spacing: 20) {
            if let arabic = dua.arabic, !arabic.isEmpty {
                Text(arabic)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.vakitText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if let transliteration = dua.transliteration, !transliteration.isEmpty {
                Text(transliteration)
                    .font(.system(size: 18, weight: .regular))
                    .italic()
                    .foregroundStyle(Color.vakitTextDim)
                    .multilineTextAlignment(.center)
            }

            Text(dua.text(language: language))
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color(hex: "#e8e0d0"))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .lineLimit(3)
        }
    }

    // MARK: Esma

    private func esmaContent(_ esma: EsmaName) -> some View {
        VStack(spacing: 20) {
            Text(esma.name(language: language))
                .font(.system(size: 56, weight: .bold, design: .serif))
                .foregroundStyle(Color.vakitText)

            Rectangle()
                .fill(Color.vakitAccent.opacity(0.4))
                .frame(width: 60, height: 2)

            Text(esma.meaning(language: language))
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Watermark

    private var watermark: some View {
        HStack {
            Spacer()
            Text("vakit.app")
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.vakitTextDim.opacity(0.6))
        }
        .padding(.horizontal, 80)
    }
}

// MARK: - İslami 8 Köşeli Yıldız Pattern

struct IslamicStarPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.38
        let points = 8

        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        // 45° döndürülmüş iç içe bir yıldız daha
        let innerPattern = path
            .rotation(.degrees(22.5), anchor: .center)
            .path(in: CGRect(
                x: rect.midX - outerRadius * 0.55,
                y: rect.midY - outerRadius * 0.55,
                width: outerRadius * 1.1,
                height: outerRadius * 1.1
            ))

        path.addPath(innerPattern)
        return path
    }
}

// MARK: - UIImage Generator

@MainActor
func generateShareImage(contentType: ShareableContentType, language: String, size: CGSize) -> UIImage? {
    let view = ShareableContentView(contentType: contentType, language: language)
        .frame(width: size.width, height: size.height)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 3.0
    return renderer.uiImage
}

// MARK: - Preview

#Preview("Verse Story") {
    let verse = Verse(
        id: "0", arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
        textTR: "Rahman ve Rahim olan Allah'ın adıyla.", textEN: "In the name of Allah, the Most Gracious, the Most Merciful.",
        surahName: "Fatiha", surahNumber: 1, verseNumber: "1",
        source: "Kur'an-ı Kerim", referenceURL: nil
    )
    ShareableContentView(contentType: .verse(verse), language: "tr")
        .frame(width: 270, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

#Preview("Hadith Square") {
    let hadith = Hadith(
        id: "0", textTR: "Ameller niyetlere göredir.", textEN: "Actions are by intentions.",
        source: "Buhari", grade: "Sahih", referenceURL: nil
    )
    ShareableContentView(contentType: .hadith(hadith), language: "tr")
        .frame(width: 270, height: 270)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

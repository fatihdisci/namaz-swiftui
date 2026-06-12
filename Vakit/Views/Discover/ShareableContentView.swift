import SwiftUI

// MARK: - Paylaşım Görseli — Tüm Günlük İçerik

/// Discover'daki tüm günlük içeriği tek Story (1080×1920) görselinde toplar.
struct ShareableContentView: View {
    let verse: Verse?
    let hadith: Hadith?
    let dua: Dua?
    let language: String

    private let size = CGSize(width: 1080, height: 1920)

    var body: some View {
        ZStack {
            auroraBackground
            IslamicStarPattern()
                .stroke(Color.vakitAccent.opacity(0.05), lineWidth: 1)
                .padding(60)

            VStack(spacing: 0) {
                wordmark
                    .padding(.top, 80)

                separator
                    .padding(.top, 20)

                contentStack
                    .padding(.horizontal, 80)
                    .padding(.top, 50)

                Spacer(minLength: 80)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color.vakitBg)
    }

    // MARK: - Arka plan

    private var auroraBackground: some View {
        ZStack {
            Color.vakitBg
            LinearGradient(
                colors: [Color.vakitBg, Color(hex: "#1a0a2e"), Color.vakitBg],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.vakitAccent.opacity(0.06))
                .frame(width: 600, height: 600)
                .blur(radius: 150)
                .offset(x: -200, y: -250)
            Circle()
                .fill(Color.fajr.opacity(0.04))
                .frame(width: 500, height: 500)
                .blur(radius: 120)
                .offset(x: 200, y: 300)
        }
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        Text("vakit.app")
            .font(.system(size: 30, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.vakitAccent)
            .tracking(3)
    }

    // MARK: - Separator

    private var separator: some View {
        Rectangle()
            .fill(Color.vakitAccent.opacity(0.25))
            .frame(width: 200, height: 1)
    }

    // MARK: - İçerik

    private var contentStack: some View {
        VStack(spacing: 50) {
            if let verse { verseSection(verse) }
            if let hadith {
                thinSeparator
                hadithSection(hadith)
            }
            if let dua {
                thinSeparator
                duaSection(dua)
            }
        }
    }

    private var thinSeparator: some View {
        Rectangle()
            .fill(Color.vakitBorder)
            .frame(height: 1)
            .padding(.horizontal, 100)
    }

    // MARK: Ayet

    private func verseSection(_ verse: Verse) -> some View {
        VStack(spacing: 24) {
            sectionLabel("Günün Ayeti", icon: "book.fill")

            if let arabic = verse.arabic, !arabic.isEmpty {
                Text(arabic)
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(Color.vakitText)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            Text("\(verse.surahName) · \(verse.verseNumber)")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.vakitAccent)

            Text(verse.text(language: language))
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color(hex: "#e8e0d0"))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .lineLimit(4)
        }
    }

    // MARK: Hadis

    private func hadithSection(_ hadith: Hadith) -> some View {
        VStack(spacing: 24) {
            sectionLabel("Günün Hadisi", icon: "text.quote")

            Text(hadith.text(language: language))
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.vakitText)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .lineLimit(5)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Text(hadith.source)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.vakitAccent)
                if !hadith.grade.isEmpty {
                    Text("·")
                        .foregroundStyle(Color.vakitTextDim)
                    Text(hadith.grade)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.vakitAccent.opacity(0.8))
                }
            }
        }
    }

    // MARK: Dua

    private func duaSection(_ dua: Dua) -> some View {
        VStack(spacing: 24) {
            sectionLabel("Günün Duası", icon: "hands.and.sparkles.fill")

            if let arabic = dua.arabic, !arabic.isEmpty {
                Text(arabic)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.vakitText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Text(dua.text(language: language))
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color(hex: "#e8e0d0"))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .lineLimit(3)
        }
    }

    // MARK: - Bölüm başlığı

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .serif))
        }
        .foregroundStyle(Color.vakitAccent)
    }
}

// MARK: - Görsel Üretici

@MainActor
func makeShareImage(verse: Verse?, hadith: Hadith?, dua: Dua?, language: String) -> UIImage? {
    let view = ShareableContentView(
        verse: verse,
        hadith: hadith,
        dua: dua,
        language: language
    )
    .frame(width: 1080, height: 1920)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    return renderer.uiImage
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

// MARK: - Preview

#Preview {
    let verse = Verse(
        id: "0", arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
        textTR: "Rahman ve Rahim olan Allah'ın adıyla.",
        textEN: "In the name of Allah, the Most Gracious, the Most Merciful.",
        surahName: "Fatiha", surahNumber: 1, verseNumber: "1",
        source: "Kur'an-ı Kerim", referenceURL: nil
    )
    let hadith = Hadith(
        id: "0",
        textTR: "Ameller niyetlere göredir. Herkes için ancak niyet ettiği şey vardır.",
        textEN: "Actions are by intentions.",
        source: "Buhari", grade: "Sahih", referenceURL: nil
    )
    let dua = Dua(
        id: "0", kind: "kurani",
        arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً",
        transliteration: "Rabbenâ âtinâ fi'd-dünyâ haseneten",
        textTR: "Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver.",
        textEN: "Our Lord! Give us in this world good and in the Hereafter good.",
        source: "Bakara Suresi, 201. Ayet", grade: nil, referenceURL: nil
    )
    ShareableContentView(verse: verse, hadith: hadith, dua: dua, language: "tr")
        .frame(width: 270, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

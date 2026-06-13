import SwiftUI

// MARK: - Paylaşım Görseli — Instagram Story (1080×1920)

/// Tüm günlük içeriği premium Instagram story görselinde toplar.
struct ShareableContentView: View {
    let verse: Verse?
    let hadith: Hadith?
    let dua: Dua?
    let esma: EsmaName?
    let language: String

    // MARK: Renk paleti

    private let gold = Color(hex: "c9a44b")
    private let goldLight = Color(hex: "e8c97a")
    private let goldMuted = Color(hex: "8b7535")
    private let cardBg = Color(hex: "0e0e1c")
    private let bgBase = Color(hex: "080812")
    private let textPrimary = Color(hex: "f0ede5")
    private let textSecondary = Color(hex: "b8b2a4")
    private let textTertiary = Color(hex: "8a8578")

    // MARK: Lokalizasyon

    private var verseLabel: String { language == "tr" ? "Günün Ayeti" : "Verse of the Day" }
    private var hadithLabel: String { language == "tr" ? "Günün Hadisi" : "Hadith of the Day" }
    private var duaLabel: String { language == "tr" ? "Günün Duası" : "Prayer of the Day" }
    private var esmaLabel: String { language == "tr" ? "Esma-ül Hüsna" : "Al-Asma al-Husna" }

    // MARK: Body

    var body: some View {
        ZStack {
            // Katman 1 — arka plan
            bgBase

            // Katman 2 — gradientler
            ambientGlow

            // Katman 3 — soft glow orblar
            glowOrbs

            // Katman 4 — İslami geometrik medallion
            GoldMedallion()
                .fill(gold.opacity(0.04))
                .frame(width: 900, height: 900)
                .offset(y: -60)

            // Katman 5 — noktasal süslemeler
            accentDots

            // Katman 6 — ana içerik
            VStack(spacing: 0) {
                header
                    .padding(.top, 140)

                Spacer().frame(height: 70)

                if let verse {
                    verseCard(verse)
                }

                if let hadith {
                    ornamentalDivider
                        .padding(.vertical, 44)
                    hadithCard(hadith)
                }

                if let dua {
                    ornamentalDivider
                        .padding(.vertical, 44)
                    duaCard(dua)
                }

                if let esma {
                    ornamentalDivider
                        .padding(.vertical, 44)
                    esmaCard(esma)
                }

                Spacer(minLength: 80)

                footer
                    .padding(.bottom, 56)
            }
            .padding(.horizontal, 100)
        }
        .frame(width: 1080, height: 1920)
    }

    // MARK: - Arka plan katmanları

    private var ambientGlow: some View {
        ZStack {
            // Sağ-üst altın sıcaklık
            RadialGradient(
                colors: [gold.opacity(0.13), gold.opacity(0.03), .clear],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 1000
            )
            // Sol-alt mor serinlik
            RadialGradient(
                colors: [Color(hex: "7c3aed").opacity(0.07), .clear],
                center: .bottomLeading,
                startRadius: 150,
                endRadius: 900
            )
            // Orta-üst hafif aydınlık
            RadialGradient(
                colors: [Color(hex: "1a1440").opacity(0.3), .clear],
                center: .top,
                startRadius: 300,
                endRadius: 800
            )
        }
    }

    private var glowOrbs: some View {
        ZStack {
            // Büyük altın orb — sağ üst
            Circle()
                .fill(gold.opacity(0.07))
                .frame(width: 520, height: 520)
                .blur(radius: 160)
                .offset(x: 320, y: -480)

            // Mor orb — sol alt
            Circle()
                .fill(Color(hex: "7c3aed").opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 140)
                .offset(x: -280, y: 520)

            // Küçük altın orb — orta
            Circle()
                .fill(gold.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -40, y: 140)
        }
    }

    private var accentDots: some View {
        ZStack {
            // Üst-sol köşe yakını
            Circle()
                .fill(gold.opacity(0.15))
                .frame(width: 4, height: 4)
                .offset(x: -420, y: -600)

            Circle()
                .fill(gold.opacity(0.08))
                .frame(width: 3, height: 3)
                .offset(x: 380, y: -560)

            // Sağ kenar
            Circle()
                .fill(gold.opacity(0.1))
                .frame(width: 5, height: 5)
                .offset(x: 440, y: -80)

            // Alt köşeler
            Circle()
                .fill(gold.opacity(0.12))
                .frame(width: 4, height: 4)
                .offset(x: -400, y: 640)
            Circle()
                .fill(gold.opacity(0.08))
                .frame(width: 3, height: 3)
                .offset(x: 410, y: 680)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 18) {
            Text("vakit.app")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(gold)
                .tracking(4)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, gold.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 180, height: 1)
        }
    }

    // MARK: - Ayet kartı

    private func verseCard(_ verse: Verse) -> some View {
        card {
            VStack(spacing: 32) {
                sectionHeader(verseLabel, icon: "book.fill")

                if let arabic = verse.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 58, weight: .medium))
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .lineSpacing(16)
                }

                HStack(spacing: 12) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(gold)
                    Text("\(verse.surahName) · \(verse.verseNumber)")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(gold)
                }

                Text(verse.text(language: language))
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .lineLimit(5)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Hadis kartı

    private func hadithCard(_ hadith: Hadith) -> some View {
        card {
            VStack(spacing: 32) {
                sectionHeader(hadithLabel, icon: "text.quote")

                Text(hadith.text(language: language))
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .lineLimit(6)
                    .padding(.horizontal, 14)

                HStack(spacing: 10) {
                    Text(hadith.source)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(gold)
                    if !hadith.grade.isEmpty {
                        Circle()
                            .fill(gold.opacity(0.4))
                            .frame(width: 5, height: 5)
                        Text(hadith.grade)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(goldMuted)
                    }
                }
            }
        }
    }

    // MARK: - Dua kartı

    private func duaCard(_ dua: Dua) -> some View {
        card {
            VStack(spacing: 32) {
                sectionHeader(duaLabel, icon: "hands.and.sparkles.fill")

                if let arabic = dua.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .lineSpacing(14)
                }

                Text(dua.text(language: language))
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .lineLimit(4)
                    .padding(.horizontal, 20)

                if !dua.source.isEmpty {
                    Text(dua.source)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(goldMuted)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Esma kartı (öne çıkarılmış)

    private func esmaCard(_ esma: EsmaName) -> some View {
        card(accentBorder: true) {
            VStack(spacing: 28) {
                sectionHeader(esmaLabel, icon: "sparkles")

                // Esma ismi — büyük, öne çıkan
                Text(esma.name(language: language))
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(goldLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(esma.meaning(language: language))
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 30)

                // Dekoratif alt çizgi
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, gold.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 120, height: 1)
            }
        }
    }

    // MARK: - Ornamental divider

    private var ornamentalDivider: some View {
        HStack(spacing: 18) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [gold.opacity(0.01), gold.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 160, height: 1)

            Image(systemName: "diamond.fill")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(gold.opacity(0.35))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [gold.opacity(0.15), gold.opacity(0.01)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 160, height: 1)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            // Küçük geometrik motif
            HStack(spacing: 6) {
                DiamondMini()
                    .fill(gold.opacity(0.2))
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(gold.opacity(0.12))
                    .frame(width: 40, height: 1)
                DiamondMini()
                    .fill(gold.opacity(0.3))
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(gold.opacity(0.12))
                    .frame(width: 40, height: 1)
                DiamondMini()
                    .fill(gold.opacity(0.2))
                    .frame(width: 6, height: 6)
            }

            Text("vakit.app")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(textTertiary)
                .tracking(3)
        }
    }

    // MARK: - Ortak bileşenler

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(gold)
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(gold)
        }
    }

    private func card(accentBorder: Bool = false, @ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        accentBorder ? gold.opacity(0.18) : gold.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .overlay(alignment: .leading) {
                // Sol kenar altın bar
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.5), gold.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .padding(.vertical, 40)
                    .padding(.leading, 1)
            }
    }
}

// MARK: - Görsel Üretici

@MainActor
func makeShareImage(
    verse: Verse?,
    hadith: Hadith?,
    dua: Dua?,
    esma: EsmaName?,
    language: String
) -> UIImage? {
    let view = ShareableContentView(
        verse: verse,
        hadith: hadith,
        dua: dua,
        esma: esma,
        language: language
    )
    .frame(width: 1080, height: 1920)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    return renderer.uiImage
}

// MARK: - İslami Geometrik Medallion (büyük merkezi motif)

struct GoldMedallion: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * 0.42
        let points = 8

        // Ana 8-köşeli yıldız
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerR : innerR
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        // Dış çember
        path.addEllipse(in: CGRect(
            x: center.x - outerR,
            y: center.y - outerR,
            width: outerR * 2,
            height: outerR * 2
        ))

        // İç çember
        path.addEllipse(in: CGRect(
            x: center.x - innerR * 0.85,
            y: center.y - innerR * 0.85,
            width: innerR * 1.7,
            height: innerR * 1.7
        ))

        // 45° döndürülmüş ikinci yıldız (içte)
        let rotatedR = outerR * 0.32
        let rotInnerR = rotatedR * 0.38
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2 + (.pi / Double(points))
            let radius = i.isMultiple(of: 2) ? rotatedR : rotInnerR
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        return path
    }
}

// MARK: - Küçük elmas (footer süsü)

struct DiamondMini: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
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
    let esma = EsmaName(
        id: "0", number: 1,
        nameTR: "er-Rahmân",
        nameEN: "ar-Rahman",
        meaningTR: "Çok Merhametli",
        meaningEN: "The Most Gracious"
    )
    ShareableContentView(
        verse: verse, hadith: hadith, dua: dua, esma: esma, language: "tr"
    )
    .frame(width: 270, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

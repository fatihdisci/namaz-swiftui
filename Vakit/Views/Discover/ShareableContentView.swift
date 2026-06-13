import SwiftUI

// MARK: - Tek içerik paylaşım görseli (1080×1920)

/// Her içerik tipi kendi PNG arka planını kullanır.
private struct SingleShareView<Content: View>: View {
    let imageName: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            if let ui = UIImage(named: imageName) {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 1080, height: 1920)
                    .clipped()
            } else {
                Color(hex: "080812")
            }

            // Hafif karartma — her arka planda yazı okunurluğu için
            Color.black.opacity(0.18)

            content()
                .padding(.horizontal, 120)
                .frame(width: 1080, height: 1920)
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Ortak renkler

private let textPrimary = Color(hex: "f0ede5")
private let textMuted = Color(hex: "b8b2a4")
private let accentGold = Color(hex: "c9a44b")

// MARK: - Verse (Ayet) paylaşım

@MainActor
func makeVerseShareImage(verse: Verse?, language: String) -> UIImage? {
    guard let verse else { return nil }
    let view = SingleShareView(imageName: "ayet") {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                sectionLabel("Günün Ayeti")

                if let arabic = verse.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(14)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(verse.text(language: language))
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(verse.surahName) · \(verse.verseNumber)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accentGold)
            }

            Spacer()
        }
    }
    .frame(width: 1080, height: 1920)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    return renderer.uiImage
}

// MARK: - Hadith (Hadis) paylaşım

@MainActor
func makeHadithShareImage(hadith: Hadith?, language: String) -> UIImage? {
    guard let hadith else { return nil }
    let view = SingleShareView(imageName: "hadis") {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                sectionLabel("Günün Hadisi")

                Text(hadith.text(language: language))
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(hadith.source)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(accentGold)
                    if !hadith.grade.isEmpty {
                        Text("·")
                            .foregroundStyle(textMuted)
                        Text(hadith.grade)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(accentGold.opacity(0.8))
                    }
                }
            }

            Spacer()
        }
    }
    .frame(width: 1080, height: 1920)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    return renderer.uiImage
}

// MARK: - Dua paylaşım

@MainActor
func makeDuaShareImage(dua: Dua?, language: String) -> UIImage? {
    guard let dua else { return nil }
    let view = SingleShareView(imageName: "dua") {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                sectionLabel("Günün Duası")

                if let arabic = dua.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(12)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(dua.text(language: language))
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .fixedSize(horizontal: false, vertical: true)

                if !dua.source.isEmpty {
                    Text(dua.source)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(accentGold)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
        }
    }
    .frame(width: 1080, height: 1920)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    return renderer.uiImage
}

// MARK: - Ortak bölüm başlığı

private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 32, weight: .semibold, design: .serif))
        .foregroundStyle(accentGold)
        .tracking(2)
}

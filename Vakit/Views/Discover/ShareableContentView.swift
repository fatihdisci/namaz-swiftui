import SwiftUI

// MARK: - Tek içerik paylaşım görseli (1080×1920)

/// Her içerik tipi kendi PNG arka planını ve yazı rengini kullanır.
private struct SingleShareView<Content: View>: View {
    let imageName: String
    var darkOverlay: CGFloat = 0.18
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

            if darkOverlay > 0 {
                Color.black.opacity(darkOverlay)
            }

            content()
                .padding(.horizontal, 120)
                .frame(width: 1080, height: 1920)
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Açık arka plan renkleri (hadis)

private let darkText = Color(hex: "1e1a14")
private let darkMuted = Color(hex: "4a4438")
private let darkGold = Color(hex: "7a5c10")

// MARK: - Koyu arka plan renkleri (ayet, dua)

private let lightText = Color(hex: "f0ede5")
private let lightMuted = Color(hex: "b8b2a4")
private let lightGold = Color(hex: "c9a44b")

// MARK: - Verse (Ayet) paylaşım — koyu arka plan

@MainActor
func makeVerseShareImage(verse: Verse?, language: String) -> UIImage? {
    guard let verse else { return nil }
    let view = SingleShareView(imageName: "ayet") {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 42) {
                sectionLabel("Günün Ayeti", color: lightGold)

                if let arabic = verse.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 66, weight: .medium))
                        .foregroundStyle(lightText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(18)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(verse.text(language: language))
                    .font(.system(size: 46, weight: .regular))
                    .foregroundStyle(lightMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(16)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(verse.surahName) · \(verse.verseNumber)")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(lightGold)
            }

            Spacer()
        }
    }
    .frame(width: 1080, height: 1920)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    return renderer.uiImage
}

// MARK: - Hadith (Hadis) paylaşım — açık arka plan

@MainActor
func makeHadithShareImage(hadith: Hadith?, language: String) -> UIImage? {
    guard let hadith else { return nil }
    let view = SingleShareView(imageName: "hadis", darkOverlay: 0) {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 42) {
                sectionLabel("Günün Hadisi", color: darkGold)

                Text(hadith.text(language: language))
                    .font(.system(size: 46, weight: .regular))
                    .foregroundStyle(darkText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(16)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(hadith.source)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(darkGold)
                    if !hadith.grade.isEmpty {
                        Text("·")
                            .foregroundStyle(darkMuted)
                        Text(hadith.grade)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(darkGold.opacity(0.8))
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

// MARK: - Dua paylaşım — koyu arka plan

@MainActor
func makeDuaShareImage(dua: Dua?, language: String) -> UIImage? {
    guard let dua else { return nil }
    let view = SingleShareView(imageName: "dua") {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 42) {
                sectionLabel("Günün Duası", color: lightGold)

                if let arabic = dua.arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(lightText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(14)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(dua.text(language: language))
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(lightMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .fixedSize(horizontal: false, vertical: true)

                if !dua.source.isEmpty {
                    Text(dua.source)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(lightGold)
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

private func sectionLabel(_ title: String, color: Color) -> some View {
    Text(title)
        .font(.system(size: 40, weight: .semibold, design: .serif))
        .foregroundStyle(color)
        .tracking(2)
}

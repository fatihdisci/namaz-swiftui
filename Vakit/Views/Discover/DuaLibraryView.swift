import SwiftUI

struct DuaLibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: DuaCategory = .all
    @State private var favoritesOnly = false
    @State private var favoriteIDs = StorageService.shared.favoriteDuaIDs
    @State private var contentRevision = 0

    @Environment(LanguageService.self) private var lang

    private var filteredDuas: [Dua] {
        DailyContent.duas.filter { dua in
            selectedCategory.contains(dua)
                && dua.matches(searchText, language: lang.currentLanguage)
                && (!favoritesOnly || favoriteIDs.contains(dua.id))
        }
    }

    var body: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 14) {
                    categoryPicker

                    if filteredDuas.isEmpty {
                        ContentUnavailableView(
                            lang.t("dua.empty.title"),
                            systemImage: "hands.and.sparkles",
                            description: Text(lang.t("dua.empty.subtitle"))
                        )
                        .foregroundStyle(Color.vakitText)
                        .padding(.top, 50)
                    } else {
                        ForEach(filteredDuas) { dua in
                            NavigationLink {
                                DuaDetailView(
                                    dua: dua,
                                    isFavorite: favoriteIDs.contains(dua.id),
                                    onToggleFavorite: { toggleFavorite(dua.id) }
                                )
                            } label: {
                                duaRow(dua)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(lang.t("dua.library.title"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: lang.t("dua.search"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favoritesOnly.toggle()
                } label: {
                    Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(Color.vakitAccent)
                }
                .accessibilityLabel(lang.t("dua.favorites"))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vakitContentUpdated)) { _ in
            contentRevision &+= 1
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DuaCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(lang.t(category.localizationKey))
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundStyle(selectedCategory == category ? Color.vakitBg : Color.vakitText)
                            .padding(.horizontal, 13)
                            .frame(height: 34)
                            .background(
                                Capsule().fill(selectedCategory == category ? Color.vakitAccent : Color.vakitSurface)
                            )
                    }
                }
            }
        }
    }

    private func duaRow(_ dua: Dua) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    if let title = dua.title(language: lang.currentLanguage) {
                        Text(title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.vakitAccent)
                    }
                    Text(dua.text(language: lang.currentLanguage))
                        .font(.body)
                        .foregroundStyle(Color.vakitText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                Spacer(minLength: 10)
                if favoriteIDs.contains(dua.id) {
                    Image(systemName: "heart.fill").foregroundStyle(Color.vakitAccent)
                }
            }
            HStack {
                Text(lang.t(dua.category.localizationKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vakitAccent)
                Spacer()
                Text(dua.source)
                    .font(.caption)
                    .foregroundStyle(Color.vakitTextDim)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.vakitBorder))
    }

    private func toggleFavorite(_ id: String) {
        StorageService.shared.toggleFavoriteDua(id: id)
        favoriteIDs = StorageService.shared.favoriteDuaIDs
    }
}

private struct DuaDetailView: View {
    let dua: Dua
    @State var isFavorite: Bool
    let onToggleFavorite: () -> Void
    @State private var showShareSheet = false

    @Environment(LanguageService.self) private var lang

    /// Paylaşım metni: başlık, Arapça, okunuş, meal ve kaynak.
    private var shareText: String {
        var parts: [String] = []
        if let title = dua.title(language: lang.currentLanguage) {
            parts.append(title)
        }
        if let arabic = dua.arabic, !arabic.isEmpty {
            parts.append(arabic)
        }
        if let transliteration = dua.transliteration, !transliteration.isEmpty {
            parts.append(lang.currentLanguage == "tr"
                ? "Okunuşu: \(transliteration)"
                : "Transliteration: \(transliteration)")
        }
        if lang.currentLanguage == "tr" {
            parts.append("Meali: \(dua.textTR)")
        } else {
            parts.append("Meaning: \(dua.textEN)")
        }
        parts.append(dua.source)
        return parts.joined(separator: "\n\n")
    }

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .isha)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let title = dua.title(language: lang.currentLanguage) {
                        Text(title)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.vakitAccent)
                    }
                    if let arabic = dua.arabic, !arabic.isEmpty {
                        Text(arabic)
                            .font(.system(size: 27, weight: .medium))
                            .lineSpacing(10)
                            .foregroundStyle(Color.vakitText)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                    if let transliteration = dua.transliteration, !transliteration.isEmpty {
                        Text(transliteration)
                            .font(.body.italic())
                            .foregroundStyle(Color.vakitTextDim)
                    }
                    Text(dua.text(language: lang.currentLanguage))
                        .font(.title3)
                        .lineSpacing(6)
                        .foregroundStyle(Color.vakitText)
                    SpeakButton(id: "dua-\(dua.id)",
                                text: dua.text(language: lang.currentLanguage),
                                tint: .isha)
                    Divider().overlay(Color.vakitBorder)
                    Label(dua.source, systemImage: "bookmark")
                        .font(.footnote)
                        .foregroundStyle(Color.vakitTextDim)
                }
                .padding(22)
                .background(Color.vakitSurface)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.vakitBorder))
                .padding(20)
            }
        }
        .navigationTitle(
            dua.title(language: lang.currentLanguage) ?? lang.t(dua.category.localizationKey)
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.vakitAccent)
                }
                .accessibilityLabel(lang.t("dua.share"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onToggleFavorite()
                    isFavorite.toggle()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(Color.vakitAccent)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [shareText])
                .presentationDetents([.medium, .large])
        }
        .onDisappear { TranslationSpeechService.shared.stop() }
    }
}

// MARK: - Paylaşım yardımcısı

/// Sistem paylaşım sayfasını SwiftUI'ye taşıyan sarmalayıcı.
private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

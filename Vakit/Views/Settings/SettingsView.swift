import SwiftUI
import SwiftData

/// Sade ayarlar: dil, şehir, ev şehri, hesaplama metodu, bildirimler, Pro, Hakkında.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var activeLocationPicker: LocationPickerPurpose?
    @State private var showProGate = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false

    @Environment(LanguageService.self) private var lang
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vakitBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(lang.t("settings.title"))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.vakitText)

                        generalSection
                        notificationsSection
                        proSection
                        if !authService.isGuest {
                            accountSection
                        }
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $activeLocationPicker) { purpose in
            // Her açılışta TAZE bir LocationSelectionViewModel sahiplenen alt view;
            // konum, view'ın kendi instance'ından üretilip geri verilir.
            LocationPickerSheet(purpose: purpose, lang: lang) { location in
                switch purpose {
                case .prayer:
                    viewModel.saveLocation(location, context: modelContext)
                case .home:
                    viewModel.saveHomeLocation(location)
                }
                activeLocationPicker = nil
            }
        }
        .sheet(isPresented: $showProGate) {
            ProGateView()
                .environment(lang)
                .environment(purchaseService)
        }
        .alert(lang.t("account.delete.title"), isPresented: $showDeleteAccountConfirm) {
            Button(lang.t("account.delete.cancel"), role: .cancel) {}
            Button(lang.t("account.delete.confirm"), role: .destructive) {
                isDeletingAccount = true
                Task {
                    await viewModel.deleteAccount(context: modelContext)
                    isDeletingAccount = false
                }
            }
        } message: {
            Text(lang.t("account.delete.message"))
        }
    }

    // MARK: - Genel

    private var generalSection: some View {
        section(titleKey: "settings.general") {
            languageRow
            divider
            cityRow
            divider
            homeCityRow
            divider
            autoLocationRow
            divider
            methodRow
        }
    }

    private var languageRow: some View {
        HStack {
            rowLabel(icon: "globe", titleKey: "settings.language")
            Spacer()
            Picker("", selection: Binding(
                get: { lang.currentLanguage },
                set: { lang.setLanguage($0) }
            )) {
                Text(lang.t("language.tr")).tag("tr")
                Text(lang.t("language.en")).tag("en")
            }
            .pickerStyle(.menu)
            .tint(Color.vakitAccent)
        }
        .padding(.vertical, 6)
    }

    private var cityRow: some View {
        Button {
            activeLocationPicker = .prayer
        } label: {
            HStack {
                rowLabel(icon: "building.2", titleKey: "settings.city")
                Spacer()
                Text(viewModel.locationDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 10)
        }
    }

    private var homeCityRow: some View {
        Button {
            activeLocationPicker = .home
        } label: {
            HStack {
                rowLabel(icon: "house.fill", titleKey: "settings.homeCity")
                Spacer()
                Text(viewModel.homeLocationDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 10)
        }
    }

    /// Opsiyonel konumla otomatik bul butonu (izin ister).
    private var autoLocationRow: some View {
        Button {
            Task { await viewModel.useAutomaticLocation(context: modelContext) }
        } label: {
            HStack {
                rowLabel(icon: "location.fill", titleKey: "location.autoFind")
                Spacer()
                if viewModel.isLocating {
                    ProgressView().tint(Color.vakitAccent)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.vakitTextDim)
                }
            }
            .padding(.vertical, 10)
        }
        .disabled(viewModel.isLocating)
    }

    private var methodRow: some View {
        HStack {
            rowLabel(icon: "function", titleKey: "settings.method")
            Spacer()
            Picker("", selection: Binding(
                get: { viewModel.method },
                set: { viewModel.setMethod($0, context: modelContext) }
            )) {
                ForEach(CalculationMethod.allCases) { option in
                    Text(lang.t(option.localizationKey)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.vakitAccent)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Bildirimler

    private var notificationsSection: some View {
        section(titleKey: "settings.notifications") {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                HStack {
                    rowLabel(icon: "bell.fill", titleKey: "settings.notifications")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.vakitTextDim)
                }
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        section(titleKey: "settings.pro") {
            Button {
                showProGate = true
            } label: {
                HStack {
                    rowLabel(icon: "sparkles", titleKey: "settings.pro")
                    Spacer()
                    Text(lang.t(purchaseService.hasProAccess ? "pro.active" : "pro.unlock"))
                        .font(.caption)
                        .foregroundStyle(
                            purchaseService.hasProAccess ? Color.vakitAccent : Color.vakitTextDim
                        )
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.vakitTextDim)
                }
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Hesap

    private var accountSection: some View {
        section(titleKey: "settings.account") {
            Button {
                authService.signOut()
            } label: {
                HStack {
                    rowLabel(icon: "rectangle.portrait.and.arrow.right", titleKey: "settings.signOut")
                    Spacer()
                }
                .padding(.vertical, 10)
            }

            divider

            Button {
                showDeleteAccountConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.maghrib)
                        .frame(width: 24)
                    Text(lang.t("settings.deleteAccount"))
                        .font(.body)
                        .foregroundStyle(Color.maghrib)
                    Spacer()
                    if isDeletingAccount {
                        ProgressView().tint(Color.maghrib)
                    }
                }
                .padding(.vertical, 10)
            }
            .disabled(isDeletingAccount)
        }
    }

    // MARK: - Hakkında

    private var aboutSection: some View {
        section(titleKey: "settings.about") {
            HStack {
                rowLabel(icon: "info.circle", titleKey: "settings.version")
                Spacer()
                Text(viewModel.appVersion)
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Yardımcılar

    private func section(titleKey: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lang.t(titleKey))
                .font(.system(.footnote, design: .default, weight: .semibold))
                .foregroundStyle(Color.vakitTextDim)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.vakitBorder, lineWidth: 1)
            )
        }
    }

    private func rowLabel(icon: String, titleKey: String) -> some View {
        rowLabel(icon: icon, title: lang.t(titleKey))
    }

    private func rowLabel(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundStyle(Color.vakitText)
        }
    }

    private var divider: some View {
        Divider().overlay(Color.vakitBorder)
    }
}

// MARK: - Location picker sheet

/// Konum seçim sheet'inin amacı. `.sheet(item:)` ile kullanıldığı için Identifiable.
enum LocationPickerPurpose: Identifiable {
    case prayer
    case home

    var id: Self { self }
}

/// Konum seçim sheet'i. KENDİ `LocationSelectionViewModel`'ini sahiplenir;
/// `.sheet(item:)` her açılışta içeriği yeniden kurduğundan model daima TAZE olur
/// (eski seçim state'i taşınmaz) ve seçilen konum aynı instance'tan üretilip
/// `onSave` ile geri verilir.
private struct LocationPickerSheet: View {
    let purpose: LocationPickerPurpose
    let lang: LanguageService
    let onSave: (PrayerLocation) -> Void

    @State private var model = LocationSelectionViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vakitBg.ignoresSafeArea()
                LocationSelectionView(viewModel: model) { location in
                    onSave(location)
                }
            }
        }
        .environment(lang)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
        .environment(LanguageService.shared)
        .environment(PurchaseService.shared)
        .environment(AuthService.shared)
        .modelContainer(for: [City.self, KazaEntry.self], inMemory: true)
        .preferredColorScheme(.dark)
}

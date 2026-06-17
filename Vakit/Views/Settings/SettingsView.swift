import SwiftUI
import SwiftData

/// Sade ayarlar: dil, şehir, ev şehri, hesaplama metodu, bildirimler, Pro, Hakkında.
struct SettingsView: View {
    private enum LocationPickerPurpose {
        case prayer
        case home
    }

    @State private var viewModel = SettingsViewModel()
    @State private var locationPickerModel = LocationSelectionViewModel()
    @State private var showLocationPicker = false
    @State private var locationPickerPurpose: LocationPickerPurpose = .prayer
    @State private var showProGate = false

    @Environment(LanguageService.self) private var lang
    @Environment(PurchaseService.self) private var purchaseService
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
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showLocationPicker) {
            locationPickerSheet
        }
        .sheet(isPresented: $showProGate) {
            ProGateView()
                .environment(lang)
                .environment(purchaseService)
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
            locationPickerModel = LocationSelectionViewModel()
            locationPickerPurpose = .prayer
            showLocationPicker = true
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
            locationPickerModel = LocationSelectionViewModel()
            locationPickerPurpose = .home
            showLocationPicker = true
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

    // MARK: - Location picker sheet (new cascading flow)

    private var locationPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.vakitBg.ignoresSafeArea()
                LocationSelectionView(viewModel: locationPickerModel) {
                    guard let location = locationPickerModel.buildPrayerLocation() else { return }
                    var loc = location
                    loc.calculationMethod = locationPickerModel.method
                    switch locationPickerPurpose {
                    case .prayer:
                        viewModel.saveLocation(loc, context: modelContext)
                    case .home:
                        viewModel.saveHomeLocation(loc)
                    }
                    showLocationPicker = false
                }
            }
        }
        .environment(lang)
        .preferredColorScheme(.dark)
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

#Preview {
    SettingsView()
        .environment(LanguageService.shared)
        .environment(PurchaseService.shared)
        .modelContainer(for: [City.self, KazaEntry.self], inMemory: true)
        .preferredColorScheme(.dark)
}

import SwiftUI
import SwiftData

/// Sade ayarlar: dil, şehir, hesaplama metodu, mezhep, bildirimler, Pro, Hakkında.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var cityPickerModel = OnboardingViewModel()
    @State private var showCityPicker = false

    @Environment(LanguageService.self) private var lang
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
        .sheet(isPresented: $showCityPicker) {
            cityPickerSheet
        }
    }

    // MARK: - Genel

    private var generalSection: some View {
        section(titleKey: "settings.general") {
            languageRow
            divider
            cityRow
            divider
            methodRow
            divider
            schoolRow
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
            let model = OnboardingViewModel()
            model.method = viewModel.method
            cityPickerModel = model
            showCityPicker = true
        } label: {
            HStack {
                rowLabel(icon: "building.2", titleKey: "settings.city")
                Spacer()
                Text(viewModel.city?.name ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 10)
        }
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

    private var schoolRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            rowLabel(icon: "sun.haze", titleKey: "settings.asrSchool")

            Picker("", selection: Binding(
                get: { viewModel.school },
                set: { viewModel.setSchool($0, context: modelContext) }
            )) {
                Text(lang.t("settings.asrStandard")).tag(0)
                Text(lang.t("settings.asrHanafi")).tag(1)
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 10)
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
            HStack {
                rowLabel(icon: "sparkles", titleKey: "settings.pro")
                Spacer()
                // Phase 6'da RevenueCat paywall'a bağlanacak.
                Text(lang.t("settings.proComingSoon"))
                    .font(.caption)
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 10)
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

    // MARK: - Şehir seçimi sheet'i (onboarding bileşeni yeniden kullanılır)

    private var cityPickerSheet: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            CitySelectionView(viewModel: cityPickerModel) {
                showCityPicker = false
                viewModel.refreshCity()
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 24)

            Text(lang.t(titleKey))
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
        .modelContainer(for: [City.self, KazaEntry.self], inMemory: true)
        .preferredColorScheme(.dark)
}

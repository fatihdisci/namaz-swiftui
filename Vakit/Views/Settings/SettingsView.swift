import SwiftUI
import SwiftData
import CoreLocation

/// Sade ayarlar: dil, şehir, ev şehri, hesaplama metodu, bildirimler, Pro, Hakkında.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var activeLocationPicker: LocationPickerPurpose?
    @State private var showProGate = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var showAsrInfoSheet = false
    @State private var showWhatsNewSheet = false

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
                            .font(.vakitScreenTitle)
                            .foregroundStyle(Color.vakitText)

                        generalSection
                        notificationsSection
                        proSection
                        #if DEBUG
                        developerSection
                        #endif
                        if !authService.isGuest {
                            accountSection
                        }
                        aboutSection
                        legalSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            cleanupFreeUserCities()
        }
        .sheet(item: $activeLocationPicker) { purpose in
            // Her açılışta TAZE bir LocationSelectionViewModel sahiplenen alt view;
            // konum, view'ın kendi instance'ından üretilip geri verilir.
            LocationPickerSheet(
                purpose: purpose,
                mode: purchaseService.hasProAccess ? .add : .edit,
                lang: lang
            ) { location in
                switch purpose {
                case .prayer:
                    viewModel.saveLocation(
                        location,
                        context: modelContext,
                        replaceExisting: !purchaseService.hasProAccess
                    )
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
        .sheet(isPresented: $showAsrInfoSheet) {
            AsrInfoSheet(method: viewModel.method)
                .environment(lang)
        }
        .sheet(isPresented: $showWhatsNewSheet) {
            WhatsNewSheet(version: viewModel.appVersion)
                .environment(lang)
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

    /// Free kullanıcıların birikmiş çoklu şehirlerini tek şehre indirger (bir kerelik göç).
    private func cleanupFreeUserCities() {
        let storage = StorageService.shared
        guard !purchaseService.hasProAccess, !storage.hasCleanedFreeCities else { return }
        if let current = storage.selectedPrayerLocation {
            storage.savedPrayerLocations = [current]
        }
        storage.hasCleanedFreeCities = true
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
            asrCalculationRow
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
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 12)
        }
    }

    private var methodRow: some View {
        VStack(alignment: .leading, spacing: 6) {
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

            Text(lang.t("method.explanation"))
                .font(.vakitReference)
                .foregroundStyle(Color.vakitTextDim)
                .padding(.horizontal, 36) // icon width (24) + spacing (12)
        }
    }

    private var asrCalculationRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                rowLabel(icon: "sun.max", titleKey: "school.title")
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.asrCalculation },
                    set: { viewModel.setAsrCalculation($0, context: modelContext) }
                )) {
                    ForEach(AsrCalculation.allCases) { option in
                        Text(lang.t(option.localizationKey)).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.vakitAccent)
            }
            .padding(.vertical, 6)

            Text(lang.t("school.explanation"))
                .font(.vakitReference)
                .foregroundStyle(Color.vakitTextDim)
                .padding(.horizontal, 36)

            if viewModel.method == .diyanet {
                Text(lang.t("school.diyanetNote"))
                    .font(.vakitReference)
                    .foregroundStyle(Color.vakitAccent)
                    .padding(.horizontal, 36)
            }

            Button {
                showAsrInfoSheet = true
            } label: {
                Text(lang.t("school.learnMore"))
                    .font(.vakitReference)
                    .foregroundStyle(Color.vakitAccent)
                    .padding(.horizontal, 36)
            }
        }
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
                .padding(.vertical, 12)
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
                        .font(.vakitReference)
                        .foregroundStyle(
                            purchaseService.hasProAccess ? Color.vakitAccent : Color.vakitTextDim
                        )
                    if !purchaseService.hasProAccess {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.vakitTextDim)
                    }
                }
                .padding(.vertical, 12)
            }
            .disabled(purchaseService.hasProAccess)
        }
    }

    #if DEBUG
    // MARK: - Geliştirici (sadece DEBUG build'lerde; archive'a dahil edilmez)

    private var developerSection: some View {
        section(titleKey: "settings.developer") {
            HStack {
                rowLabel(icon: "hammer.fill", titleKey: "settings.developer.proOverride")
                Spacer()
                Toggle(
                    "",
                    isOn: Binding(
                        get: { purchaseService.hasProAccess },
                        set: { purchaseService.setDebugProOverride($0) }
                    )
                )
                .labelsHidden()
                .tint(Color.vakitAccent)
            }
            .padding(.vertical, 12)
        }
    }
    #endif

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
                .padding(.vertical, 12)
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
                        .font(.vakitBody)
                        .foregroundStyle(Color.maghrib)
                    Spacer()
                    if isDeletingAccount {
                        ProgressView().tint(Color.maghrib)
                    }
                }
                .padding(.vertical, 12)
            }
            .disabled(isDeletingAccount)
        }
    }

    // MARK: - Hakkında

    private var aboutSection: some View {
        section(titleKey: "settings.about") {
            Button {
                showWhatsNewSheet = true
            } label: {
                HStack {
                    rowLabel(icon: "sparkles", titleKey: "settings.whatsNew")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.vakitTextDim)
                }
                .padding(.vertical, 12)
            }

            divider

            HStack {
                rowLabel(icon: "info.circle", titleKey: "settings.version")
                Spacer()
                Text(viewModel.appVersion)
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Yasal

    private var legalSection: some View {
        section(titleKey: "legal.title") {
            Link(destination: legalURL(for: lang.currentLanguage == "tr"
                                       ? "gizlilik-politikasi.html"
                                       : "privacy-policy.html")) {
                HStack {
                    rowLabel(icon: "lock.shield", titleKey: "legal.privacy")
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.vakitTextDim)
                }
                .padding(.vertical, 12)
            }

            divider

            Link(destination: legalURL(for: lang.currentLanguage == "tr"
                                       ? "kullanim-kosullari.html#"
                                       : "terms-of-service.html")) {
                HStack {
                    rowLabel(icon: "doc.text", titleKey: "legal.terms")
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.vakitTextDim)
                }
                .padding(.vertical, 12)
            }
        }
    }

    private func legalURL(for page: String) -> URL {
        URL(string: "https://namaz-swiftui.vercel.app/\(page)")!
    }

    // MARK: - Yardımcılar

    private func section(titleKey: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t(titleKey))
                .font(.vakitSectionHeader)
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
                .font(.vakitBody)
                .foregroundStyle(Color.vakitText)
        }
    }

    private var divider: some View {
        Divider().overlay(Color.vakitBorder)
    }
}

// MARK: - Location picker sheet

/// Konum seçici modu.
/// - `.add`: Tam yetkili — kayıtlı şehirler listesi, maksimum limit denetimi (Pro).
/// - `.edit`: Yalnızca mevcut şehri değiştirme — kayıtlı liste gizlenir (Free).
enum LocationPickerMode {
    case add
    case edit
}

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
struct LocationPickerSheet: View {
    let purpose: LocationPickerPurpose
    let mode: LocationPickerMode
    let lang: LanguageService
    let onSave: (PrayerLocation) -> Void

    @State private var model = LocationSelectionViewModel()
    @State private var savedLocations: [PrayerLocation] = []
    @State private var showCityLimitAlert = false
    @State private var showCityDuplicateAlert = false
    @State private var isAutoLocating = false
    @State private var autoLocateError: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let storage = StorageService.shared
    private let maxSavedCities = 10
    private let locationService = LocationService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vakitBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        autoLocateButton

                        if let error = autoLocateError {
                            Text(error)
                                .font(.vakitCaption)
                                .foregroundStyle(Color.maghrib)
                                .padding(.horizontal, 24)
                        }

                        LocationSelectionView(viewModel: model) { location in
                            handleCitySelection(location)
                        }

                        if !savedLocations.isEmpty && mode == .add {
                            savedCitiesSection
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(mode == .add
                         ? (purpose == .home ? lang.t("safar.homeCity") : lang.t("settings.city"))
                         : lang.t("settings.cityEdit"))
                        .font(.vakitHeadline)
                        .foregroundStyle(Color.vakitText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.vakitTextDim)
                    }
                }
            }
        }
        .environment(lang)
        .preferredColorScheme(.dark)
        .onAppear {
            savedLocations = storage.savedPrayerLocations
        }
        .alert(lang.t("cityLimit.title"), isPresented: $showCityLimitAlert) {
            Button(lang.t("cityLimit.ok"), role: .cancel) {}
        } message: {
            Text(lang.t("cityLimit.message"))
        }
        .alert(lang.t("cityDuplicate.title"), isPresented: $showCityDuplicateAlert) {
            Button(lang.t("cityDuplicate.ok"), role: .cancel) {}
        } message: {
            Text(lang.t("cityDuplicate.message"))
        }
    }

    // MARK: - Auto Locate

    private var autoLocateButton: some View {
        Button {
            Task { await performAutoLocate() }
        } label: {
            HStack(spacing: 12) {
                if isAutoLocating {
                    ProgressView()
                        .tint(Color.vakitAccent)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vakitAccent)
                }
                Text(lang.t("location.autoFind"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Color.vakitAccent)
                Spacer()
            }
            .padding(16)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.vakitBorder, lineWidth: 1)
            )
        }
        .disabled(isAutoLocating)
        .padding(.horizontal, 20)
    }

    private func performAutoLocate() async {
        isAutoLocating = true
        autoLocateError = nil
        defer { isAutoLocating = false }

        do {
            let location = try await locationService.requestOneShotLocation()
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                autoLocateError = lang.t("error.location")
                return
            }

            let prayerLocation = PrayerLocation(
                countryCode: placemark.isoCountryCode ?? "",
                countryName: placemark.country ?? "",
                admin1Name: placemark.administrativeArea ?? "",
                admin1Type: PrayerLocation.admin1Label(for: placemark.isoCountryCode ?? ""),
                admin2Name: placemark.locality ?? placemark.subAdministrativeArea ?? "",
                admin2Type: PrayerLocation.admin2Label(for: placemark.isoCountryCode ?? ""),
                cityName: placemark.locality ?? placemark.administrativeArea ?? "",
                districtName: placemark.subLocality ?? "",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timeZoneIdentifier: placemark.timeZone?.identifier ?? TimeZone.current.identifier,
                calculationMethod: PrayerLocation.defaultMethod(for: placemark.isoCountryCode ?? "")
            )
            handleCitySelection(prayerLocation)
        } catch LocationService.LocationError.denied {
            autoLocateError = lang.t("qibla.permissionDenied")
        } catch {
            autoLocateError = lang.t("error.location")
        }
    }

    private func handleCitySelection(_ location: PrayerLocation) {
        let isNew = !storage.savedPrayerLocations.contains(where: { $0.id == location.id })
        let isDuplicate = storage.savedPrayerLocations.contains(where: {
            $0.shortName == location.shortName && $0.countryName == location.countryName && $0.id != location.id
        })

        if isDuplicate {
            showCityDuplicateAlert = true
        } else if mode == .add && isNew && storage.savedPrayerLocations.count >= maxSavedCities {
            showCityLimitAlert = true
        } else {
            onSave(location)
        }
    }

    private var savedCitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("settings.savedCities"))
                .font(.vakitSectionHeader)
                .foregroundStyle(Color.vakitTextDim)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(savedLocations) { location in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.shortName)
                                .font(.system(.body, weight: .medium))
                                .foregroundStyle(Color.vakitText)
                            Text(location.subtitle)
                                .font(.system(.caption))
                                .foregroundStyle(Color.vakitTextDim)
                        }
                        Spacer()
                        Button {
                            if reduceMotion {
                                storage.removeSavedPrayerLocation(id: location.id)
                                savedLocations = storage.savedPrayerLocations
                            } else {
                                withAnimation {
                                    storage.removeSavedPrayerLocation(id: location.id)
                                    savedLocations = storage.savedPrayerLocations
                                }
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.maghrib.opacity(0.7))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.vakitTextDim)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleCitySelection(location)
                    }

                    if location.id != savedLocations.last?.id {
                        Divider().overlay(Color.vakitBorder)
                    }
                }
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
        .padding(.horizontal, 20)
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

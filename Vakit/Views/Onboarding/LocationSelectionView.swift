import SwiftUI

/// Cascading konum seçimi: Ülke → Admin1 (İl/State) → Admin2 (İlçe/City).
/// Onboarding akışında CitySelectionView yerine kullanılır.
struct LocationSelectionView: View {
    @Bindable var viewModel: LocationSelectionViewModel
    let onContinue: () -> Void

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            titleSection

            countryPickerRow
            divider

            if viewModel.useCascadingFlow {
                cascadingPickers
            } else {
                manualSearchSection
            }

            if let errorKey = viewModel.errorKey {
                Text(lang.t(errorKey))
                    .font(.footnote)
                    .foregroundStyle(Color.maghrib)
            }

            MethodSelectionView(method: $viewModel.method)

            Spacer()

            continueButton
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lang.t("location.title"))
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vakitText)
            Text(lang.t("location.subtitle"))
                .font(.subheadline)
                .foregroundStyle(Color.vakitTextDim)
        }
        .padding(.top, 32)
    }

    // MARK: - Country picker

    private var countryPickerRow: some View {
        Button {
            viewModel.showCountryPicker = true
        } label: {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.vakitAccent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.t("location.country"))
                        .font(.caption)
                        .foregroundStyle(Color.vakitTextDim)
                    Text(viewModel.selectedCountryName.isEmpty
                         ? lang.t("location.selectCountry")
                         : viewModel.selectedCountryName)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(Color.vakitText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(14)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.vakitBorder, lineWidth: 1)
            )
        }
        .sheet(isPresented: $viewModel.showCountryPicker) {
            countryPickerSheet
        }
    }

    private var countryPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.vakitBg.ignoresSafeArea()
                List(viewModel.countries) { country in
                    Button {
                        viewModel.selectCountry(country)
                        viewModel.showCountryPicker = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(country.name)
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(Color.vakitText)
                                Text(country.code)
                                    .font(.caption)
                                    .foregroundStyle(Color.vakitTextDim)
                            }
                            Spacer()
                            if viewModel.selectedCountryCode == country.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.vakitAccent)
                            }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Color.vakitSurface)
                    .listRowSeparatorTint(Color.vakitBorder)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(lang.t("location.selectCountry"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang.t("pro.error.ok")) {
                        viewModel.showCountryPicker = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Cascading pickers (Turkey)

    private var cascadingPickers: some View {
        VStack(spacing: 12) {
            admin1Picker
            if viewModel.selectedAdmin1 != nil {
                admin2Picker
            }
        }
    }

    private var admin1Picker: some View {
        NavigationLink {
            admin1SelectionSheet
        } label: {
            pickerRow(
                icon: "building.2",
                label: viewModel.admin1Label,
                value: viewModel.selectedAdmin1?.name ?? lang.t("location.selectPrompt", viewModel.admin1Label)
            )
        }
    }

    private var admin2Picker: some View {
        NavigationLink {
            admin2SelectionSheet
        } label: {
            pickerRow(
                icon: "mappin.and.ellipse",
                label: viewModel.admin2Label,
                value: viewModel.selectedAdmin2?.name ?? lang.t("location.selectPrompt", viewModel.admin2Label)
            )
        }
    }

    private func pickerRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.vakitTextDim)
                Text(value)
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(Color.vakitText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.vakitTextDim)
        }
        .padding(14)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }

    // MARK: - Admin1 selection sheet

    private var admin1SelectionSheet: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            List(viewModel.admin1List) { admin in
                Button {
                    viewModel.selectAdmin1(admin)
                } label: {
                    HStack {
                        Text(admin.name)
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(Color.vakitText)
                        Spacer()
                        if viewModel.selectedAdmin1?.id == admin.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.vakitAccent)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .listRowBackground(Color.vakitSurface)
                .listRowSeparatorTint(Color.vakitBorder)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(viewModel.admin1Label)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Admin2 selection sheet

    private var admin2SelectionSheet: some View {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            List(viewModel.admin2List) { admin in
                Button {
                    viewModel.selectAdmin2(admin)
                } label: {
                    HStack {
                        Text(admin.name)
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(Color.vakitText)
                        Spacer()
                        if viewModel.selectedAdmin2?.id == admin.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.vakitAccent)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .listRowBackground(Color.vakitSurface)
                .listRowSeparatorTint(Color.vakitBorder)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(viewModel.admin2Label)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Manual search (non-Turkey)

    private var manualSearchSection: some View {
        VStack(spacing: 12) {
            // Search field
            HStack(spacing: 10) {
                if viewModel.isSearching {
                    ProgressView().tint(Color.vakitTextDim)
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.vakitTextDim)
                }

                TextField(
                    "",
                    text: Binding(
                        get: { viewModel.manualCityQuery },
                        set: { viewModel.searchCity(query: $0) }
                    ),
                    prompt: Text(lang.t("location.searchPlaceholder"))
                        .foregroundStyle(Color.vakitTextDim)
                )
                .foregroundStyle(Color.vakitText)
                .autocorrectionDisabled()
                .submitLabel(.search)
            }
            .padding(14)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.vakitBorder, lineWidth: 1)
            )

            // Results
            ForEach(viewModel.manualCityResults, id: \.id) { city in
                Button {
                    viewModel.selectManualCity(city)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .font(.system(.body, weight: .medium))
                                .foregroundStyle(Color.vakitText)
                            if !city.country.isEmpty {
                                Text(city.country)
                                    .font(.footnote)
                                    .foregroundStyle(Color.vakitTextDim)
                            }
                        }
                        Spacer()
                        if viewModel.selectedManualCity?.id == city.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.vakitAccent)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(viewModel.selectedManualCity?.id == city.id
                                  ? Color.vakitAccent.opacity(0.12)
                                  : Color.vakitSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                viewModel.selectedManualCity?.id == city.id
                                    ? Color.vakitAccent.opacity(0.4)
                                    : Color.vakitBorder,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button(action: onContinue) {
            Text(lang.t("onboarding.city.continue"))
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.vakitText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canContinue ? Color.vakitAccent : Color.vakitSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!viewModel.canContinue)
        .padding(.bottom, 24)
    }

    // MARK: - Divider

    private var divider: some View {
        Divider().overlay(Color.vakitBorder)
    }
}

#Preview {
    NavigationStack {
        ZStack {
            Color.vakitBg.ignoresSafeArea()
            LocationSelectionView(viewModel: LocationSelectionViewModel()) {}
        }
    }
    .environment(LanguageService.shared)
    .preferredColorScheme(.dark)
}

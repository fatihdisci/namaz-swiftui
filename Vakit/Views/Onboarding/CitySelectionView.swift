import SwiftUI
import SwiftData

/// Şehir arama (Aladhan /cityInfo, 400ms debounce) + konumdan bulma + metod seçimi.
struct CitySelectionView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @Environment(LanguageService.self) private var lang
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(lang.t("onboarding.city.title"))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.vakitText)
                Text(lang.t("onboarding.city.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.top, 32)

            searchField

            Button {
                Task { await viewModel.useCurrentLocation() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLocating {
                        ProgressView().tint(Color.vakitAccent)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text(lang.t("onboarding.city.useLocation"))
                }
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Color.vakitAccent)
            }
            .disabled(viewModel.isLocating)

            if let errorKey = viewModel.errorKey {
                Text(lang.t(errorKey))
                    .font(.footnote)
                    .foregroundStyle(Color.maghrib)
            }

            resultsList

            MethodSelectionView(
                method: $viewModel.method,
                asrCalculation: $viewModel.asrCalculation
            )

            Spacer()

            Button {
                viewModel.saveSelectedCity(context: modelContext)
                onContinue()
            } label: {
                Text(lang.t("onboarding.city.continue"))
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.selectedCity == nil ? Color.vakitSurface : Color.vakitAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(viewModel.selectedCity == nil)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            if viewModel.isSearching {
                ProgressView().tint(Color.vakitTextDim)
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.vakitTextDim)
            }

            TextField(
                "",
                text: $viewModel.searchQuery,
                prompt: Text(lang.t("onboarding.city.searchPlaceholder"))
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
    }

    private var resultsList: some View {
        VStack(spacing: 4) {
            ForEach(viewModel.results, id: \.id) { city in
                Button {
                    viewModel.select(city)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .font(.system(.body, weight: .medium))
                                .foregroundStyle(Color.vakitText)
                        }
                        Spacer()
                        if viewModel.selectedCity?.id == city.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.vakitAccent)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(viewModel.selectedCity?.id == city.id
                                  ? Color.vakitAccent.opacity(0.12)
                                  : Color.vakitSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                viewModel.selectedCity?.id == city.id
                                    ? Color.vakitAccent.opacity(0.4)
                                    : Color.vakitBorder,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.vakitBg.ignoresSafeArea()
        CitySelectionView(viewModel: OnboardingViewModel()) {}
    }
    .environment(LanguageService.shared)
    .modelContainer(for: [City.self, KazaEntry.self], inMemory: true)
}

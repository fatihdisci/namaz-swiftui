import SwiftUI

/// Hesaplama metodu seçici. Varsayılan: Diyanet.
struct MethodSelectionView: View {
    @Binding var method: CalculationMethod

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.t("onboarding.method.title"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.vakitText)

            Text(lang.t("onboarding.method.subtitle"))
                .font(.footnote)
                .foregroundStyle(Color.vakitTextDim)

            Picker(lang.t("onboarding.method.title"), selection: $method) {
                ForEach(CalculationMethod.allCases) { option in
                    Text(lang.t(option.localizationKey))
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.vakitAccent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.vakitBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.vakitBg.ignoresSafeArea()
        MethodSelectionView(method: .constant(.diyanet))
            .padding()
    }
    .environment(LanguageService.shared)
}

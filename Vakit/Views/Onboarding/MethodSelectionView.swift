import SwiftUI

/// Hesaplama metodu seçici. Varsayılan: Diyanet.
struct MethodSelectionView: View {
    @Binding var method: CalculationMethod
    @Binding var asrCalculation: AsrCalculation

    @Environment(LanguageService.self) private var lang

    @State private var showInfoSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lang.t("onboarding.method.title"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.vakitText)

                Spacer()

                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.vakitAccent)
                }
            }

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

            Text(lang.t("method.explanation"))
                .font(.caption)
                .foregroundStyle(Color.vakitTextDim)
                .padding(.bottom, 4)

            Text(lang.t("school.title"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.vakitText)
                .padding(.top, 8)

            Picker(lang.t("school.title"), selection: $asrCalculation) {
                ForEach(AsrCalculation.allCases) { option in
                    Text(lang.t(option.localizationKey)).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Text(lang.t("school.explanation"))
                .font(.caption)
                .foregroundStyle(Color.vakitTextDim)

            if method == .diyanet {
                Text(lang.t("school.diyanetNote"))
                    .font(.caption)
                    .foregroundStyle(Color.vakitAccent)
                    .padding(.top, 2)
            }

            Button {
                showInfoSheet = true
            } label: {
                Text(lang.t("school.learnMore"))
                    .font(.caption)
                    .foregroundStyle(Color.vakitAccent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            AsrInfoSheet(method: method)
                .environment(lang)
        }
    }
}

#Preview {
    ZStack {
        Color.vakitBg.ignoresSafeArea()
        MethodSelectionView(method: .constant(.diyanet), asrCalculation: .constant(.standard))
            .padding()
    }
    .environment(LanguageService.shared)
}

import SwiftUI

/// Hesaplama yöntemleri ve ikindi (Asr) mezhebi hakkında açıklama sheet'i.
/// MethodSelectionView ve SettingsView'daki "ⓘ" butonundan açılır.
struct AsrInfoSheet: View {
    let method: CalculationMethod

    @Environment(LanguageService.self) private var lang
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    methodSection
                    asrSection
                    diyanetSection
                    sourceSection
                }
                .padding(20)
            }
            .background(Color.vakitBg)
            .navigationTitle(lang.t("asrInfo.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang.t("common.close")) {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Method section

    private var methodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.t("onboarding.method.title"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(Color.vakitText)

            Text(lang.t("method.explanation"))
                .font(.subheadline)
                .foregroundStyle(Color.vakitTextDim)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(CalculationMethod.allCases) { m in
                    HStack {
                        Text(lang.t(m.localizationKey))
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(Color.vakitText)
                        Spacer()
                        Text(m.recommendedAsrCalculation.localizationKey)
                            .font(.caption)
                            .foregroundStyle(Color.vakitTextDim)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(12)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Asr section

    private var asrSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.t("school.title"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(Color.vakitText)

            Text(lang.t("school.explanation"))
                .font(.subheadline)
                .foregroundStyle(Color.vakitTextDim)

            HStack(spacing: 12) {
                ForEach(AsrCalculation.allCases) { school in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lang.t(school.localizationKey))
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(Color.vakitAccent)
                        Text(school == .standard
                             ? lang.t("prayer.asr")
                             : lang.t("prayer.asr"))
                            .font(.caption)
                            .foregroundStyle(Color.vakitTextDim)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.vakitSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    // MARK: - Diyanet note

    private var diyanetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if method == .diyanet {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.vakitAccent)
                    Text(lang.t("school.diyanetNote"))
                        .font(.subheadline)
                        .foregroundStyle(Color.vakitText)
                }
                .padding(12)
                .background(Color.vakitAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Source

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider().overlay(Color.vakitBorder)

            Text(lang.t("school.source"))
                .font(.caption2)
                .foregroundStyle(Color.vakitTextDim)
        }
        .padding(.top, 4)
    }
}

#Preview {
    AsrInfoSheet(method: .diyanet)
        .environment(LanguageService.shared)
}

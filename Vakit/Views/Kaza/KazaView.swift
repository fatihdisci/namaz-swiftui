import SwiftUI

struct KazaView: View {
    @State private var viewModel = KazaViewModel()

    @Environment(LanguageService.self) private var lang

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .fajr)

            ScrollView {
                VStack(spacing: 20) {
                    totalCard

                    VStack(spacing: 12) {
                        ForEach(KazaViewModel.prayers) { prayer in
                            counterRow(for: prayer)
                        }
                    }

                    privacyNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(lang.t("kaza.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalCard: some View {
        VStack(spacing: 8) {
            Text(lang.t("kaza.total"))
                .font(.vakitCaption)
                .foregroundStyle(Color.vakitTextDim)

            Text("\(viewModel.totalCount)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vakitText)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }

    private func counterRow(for prayer: Prayer) -> some View {
        HStack(spacing: 16) {
            Image(systemName: prayer.systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(prayer.accentColor)
                .frame(width: 40, height: 40)
                .background(Circle().fill(prayer.accentColor.opacity(0.12)))

            Text(lang.t(prayer.localizationKey))
                .font(.vakitBodyRounded)
                .foregroundStyle(Color.vakitText)

            Spacer()

            counterButton(systemImage: "minus", isDisabled: viewModel.count(for: prayer) == 0) {
                handleCounterAction { viewModel.decrement(prayer) }
            }

            Text("\(viewModel.count(for: prayer))")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vakitText)
                .frame(minWidth: 38)
                .contentTransition(.numericText())

            counterButton(systemImage: "plus") {
                handleCounterAction { viewModel.increment(prayer) }
            }
        }
        .padding(16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }

    private func counterButton(
        systemImage: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDisabled ? Color.vakitTextDim : Color.vakitText)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(isDisabled ? Color.vakitBorder : Color.vakitAccent)
                )
        }
        .disabled(isDisabled)
    }

    private func handleCounterAction(action: @escaping () -> Void) {
        action()
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield")
            Text(lang.t("kaza.storageNote"))
        }
        .font(.vakitReference)
        .foregroundStyle(Color.vakitTextDim)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        KazaView()
    }
    .environment(LanguageService.shared)
    .preferredColorScheme(.dark)
}

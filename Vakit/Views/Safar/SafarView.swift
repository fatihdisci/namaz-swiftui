import SwiftUI
import UIKit

/// Seferi sekmesi: mesafe hesabı + seferîlik bilgilendirmesi.
/// "Bu bilgilendirme amaçlıdır, fetva değildir" uyarısı her zaman görünür.
struct SafarView: View {
    @State private var viewModel = SafarViewModel()
    @State private var showProGate = false
    @State private var showHomeCityPicker = false

    @Environment(LanguageService.self) private var lang
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .dhuhr)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    homeCityCard
                    checkButton
                    resultSection
                    noteCard
                    infoSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .blur(radius: purchaseService.hasProAccess ? 0 : 8)
            .allowsHitTesting(purchaseService.hasProAccess)

            if !purchaseService.hasProAccess {
                Button {
                    showProGate = true
                } label: {
                    Label(lang.t("pro.unlock"), systemImage: "lock.fill")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.vakitText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.vakitAccent)
                        .clipShape(Capsule())
                }
            }
        }
        .task {
            await purchaseService.refresh()
            showProGate = !purchaseService.hasProAccess
        }
        .onReceive(NotificationCenter.default.publisher(for: .vakitHomePrayerLocationChanged)) { _ in
            viewModel.refreshHomeLocation()
        }
        .sheet(isPresented: $showProGate) {
            ProGateView(context: .safar)
                .environment(lang)
                .environment(purchaseService)
        }
        .sheet(isPresented: $showHomeCityPicker) {
            LocationPickerSheet(purpose: .home, mode: .add, lang: lang) { location in
                StorageService.shared.homePrayerLocation = location
                viewModel.refreshHomeLocation()
                showHomeCityPicker = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lang.t("safar.title"))
                .font(.vakitScreenTitle)
                .foregroundStyle(Color.vakitText)
            Text(lang.t("safar.description"))
                .font(.vakitCaption)
                .foregroundStyle(Color.vakitTextDim)
        }
    }

    private var homeCityCard: some View {
        Button {
            showHomeCityPicker = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.vakitAccent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.vakitAccent.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.t("safar.homeCity"))
                        .font(.vakitReference)
                        .foregroundStyle(Color.vakitTextDim)
                    Text(homeCityLabel)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(Color.vakitText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(16)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.vakitBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var homeCityLabel: String {
        guard let home = viewModel.homeLocation else { return lang.t("safar.noHomeCity") }
        return home.displayName
    }

    private var checkButton: some View {
        Button {
            Task { await viewModel.checkDistance() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.state == .locating {
                    ProgressView()
                        .tint(Color.vakitText)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(lang.t("safar.checkLocation"))
                    .font(.vakitBodyRounded)
            }
            .foregroundStyle(Color.vakitText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.vakitAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(viewModel.state == .locating || viewModel.homeCity == nil)
        .opacity(viewModel.homeCity == nil ? 0.5 : 1)
    }

    @ViewBuilder
    private var resultSection: some View {
        switch viewModel.state {
        case .result(let distance, let isSafar):
            VStack(spacing: 8) {
                Text(lang.t(isSafar ? "safar.traveler" : "safar.notTraveler"))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(isSafar ? Color.vakitAccent : Color.vakitText)

                Text(lang.t("safar.distanceFromHome", String(format: "%.1f", distance)))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background((isSafar ? Color.vakitAccent : Color.vakitText).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSafar ? Color.vakitAccent.opacity(0.35) : Color.vakitBorder,
                        lineWidth: 1
                    )
            )

        case .denied:
            VStack(spacing: 12) {
                Text(lang.t("qibla.permissionDenied"))
                    .font(.vakitCaption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.vakitTextDim)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Text(lang.t("qibla.openSettings"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.vakitAccent)
                }
            }
            .frame(maxWidth: .infinity)

        case .error(let messageKey):
            Text(lang.t(messageKey))
                .font(.vakitCaption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.maghrib)
                .frame(maxWidth: .infinity)

        case .locating:
            HStack(spacing: 12) {
                ProgressView()
                    .tint(Color.vakitAccent)
                Text(lang.t("safar.checkLocation"))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
            }
            .frame(maxWidth: .infinity)
            .padding(20)

        case .idle:
            EmptyView()
        }
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lang.t("safar.threshold", Int(SafarService.thresholdKm)))
                .font(.system(.footnote, design: .default, weight: .semibold))
                .foregroundStyle(Color.vakitText)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield")
                    .font(.vakitReference)
                Text(lang.t("safar.homePrivacyNote"))
                    .font(.vakitReference)
            }
            .foregroundStyle(Color.vakitTextDim)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(lang.t("safar.infoTitle"))
                .font(.system(.headline, design: .default, weight: .semibold))
                .foregroundStyle(Color.vakitText)

            ForEach(["safar.infoWhat", "safar.infoDistance", "safar.infoPrayer"], id: \.self) { key in
                Text(lang.t(key))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitTextDim)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(lang.t("safar.infoSource"))
                .font(.caption2)
                .foregroundStyle(Color.vakitTextDim.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sunrise)

                Text(lang.t("safar.disclaimer"))
                    .font(.vakitCaption)
                    .foregroundStyle(Color.vakitText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sunrise.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.sunrise.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

#Preview {
    SafarView()
        .environment(LanguageService.shared)
        .environment(PurchaseService.shared)
        .preferredColorScheme(.dark)
}

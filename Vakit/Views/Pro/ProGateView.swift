import SwiftUI

struct ProGateView: View {
    var isPreview = false

    @Environment(LanguageService.self) private var lang
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: PurchaseService.ProductID = .yearly
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(accentColor: .fajr)

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        features
                        productCards
                        purchaseButton
                        restoreButton
                        policyText
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.vakitTextDim)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await purchaseService.refresh()
            if purchaseService.hasProAccess && !isPreview {
                dismiss()
            }
        }
        .alert(lang.t("pro.error.title"), isPresented: errorBinding) {
            Button(lang.t("pro.error.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? lang.t("pro.error.generic"))
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.vakitAccent)

            Text(lang.t("settings.pro"))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vakitText)

            Text(lang.t("pro.subtitle"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.vakitTextDim)
        }
    }

    private var features: some View {
        VStack(spacing: 14) {
            featureRow(icon: "airplane", titleKey: "pro.feature.safar")
            featureRow(icon: "checklist", titleKey: "pro.feature.kaza")
            featureRow(icon: "building.2", titleKey: "pro.feature.cities")
        }
        .padding(18)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
    }

    private func featureRow(icon: String, titleKey: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 28)

            Text(lang.t(titleKey))
                .foregroundStyle(Color.vakitText)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.vakitAccent)
        }
    }

    private var productCards: some View {
        VStack(spacing: 12) {
            productCard(id: .monthly, titleKey: "pro.monthly")
            productCard(id: .yearly, titleKey: "pro.yearly", isPopular: true)
            productCard(id: .lifetime, titleKey: "pro.lifetime")
        }
    }

    private func productCard(
        id: PurchaseService.ProductID,
        titleKey: String,
        isPopular: Bool = false
    ) -> some View {
        Button {
            selectedProductID = id
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selectedProductID == id ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(Color.vakitAccent)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(lang.t(titleKey))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.vakitText)

                        if isPopular {
                            Text(lang.t("pro.popular"))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.vakitText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.vakitAccent)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Text(price(for: id))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
            }
            .padding(16)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        selectedProductID == id ? Color.vakitAccent : Color.vakitBorder,
                        lineWidth: selectedProductID == id ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        Button {
            Task { await purchaseSelectedProduct() }
        } label: {
            HStack(spacing: 10) {
                if isProcessing {
                    ProgressView().tint(Color.vakitText)
                }
                Text(lang.t("pro.purchase"))
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
            .foregroundStyle(Color.vakitText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.vakitAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isProcessing || purchaseService.product(for: selectedProductID) == nil)
        .opacity(purchaseService.product(for: selectedProductID) == nil ? 0.55 : 1)
    }

    private var restoreButton: some View {
        Button(lang.t("pro.restore")) {
            Task { await restorePurchases() }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.vakitAccent)
        .disabled(isProcessing)
    }

    private var policyText: some View {
        Text(lang.t("pro.cancellationPolicy"))
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.vakitTextDim)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func price(for id: PurchaseService.ProductID) -> String {
        purchaseService.product(for: id)?.localizedPrice ?? lang.t("pro.priceUnavailable")
    }

    private func purchaseSelectedProduct() async {
        guard let product = purchaseService.product(for: selectedProductID) else { return }
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await purchaseService.purchase(product: product)
            if purchaseService.hasProAccess && !isPreview {
                dismiss()
            }
        } catch PurchaseService.ServiceError.entitlementNotActive {
            errorMessage = lang.t("pro.error.entitlement")
        } catch {
            errorMessage = lang.t("pro.error.generic")
        }
    }

    private func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await purchaseService.restorePurchases()
            if purchaseService.hasProAccess {
                if !isPreview {
                    dismiss()
                }
            } else {
                errorMessage = lang.t("pro.restore.none")
            }
        } catch {
            errorMessage = lang.t("pro.error.generic")
        }
    }
}

#Preview {
    ProGateView()
        .environment(LanguageService.shared)
        .environment(PurchaseService.shared)
}

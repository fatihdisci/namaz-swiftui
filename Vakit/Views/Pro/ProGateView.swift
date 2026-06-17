import SwiftUI
import AuthenticationServices

struct ProGateView: View {
    var isPreview = false

    @Environment(LanguageService.self) private var lang
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: PurchaseService.ProductID = .yearly
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let termsURL = URL(string: "https://example.com/ufuk/terms")!
    private let privacyURL = URL(string: "https://example.com/ufuk/privacy")!

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(accentColor: .fajr)

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        primaryActionPanel
                        purchaseButton
                        restoreButton
                        legalLinks
                        features
                        productCards
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
        .padding(.top, 4)
    }

    private var primaryActionPanel: some View {
        VStack(spacing: 10) {
            Text(lang.t("pro.selectedPlan"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vakitTextDim)
                .textCase(.uppercase)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(productTitle(for: selectedProductID))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.vakitText)
                    Text(authService.isGuest ? lang.t("pro.signInRequired") : lang.t("pro.readyToPurchase"))
                        .font(.footnote)
                        .foregroundStyle(Color.vakitTextDim)
                }

                Spacer()

                Text(price(for: selectedProductID))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.vakitAccent)
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
        Group {
            if authService.isGuest {
                VStack(spacing: 8) {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        Task { await authService.handleSignInResult(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .disabled(authService.isSigningIn)

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.maghrib)
                    }
                }
            } else {
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
                    .foregroundStyle(Color.vakitBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vakitAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isProcessing || purchaseService.product(for: selectedProductID) == nil)
                .opacity(purchaseService.product(for: selectedProductID) == nil ? 0.55 : 1)
            }
        }
    }

    private var restoreButton: some View {
        Button(lang.t("pro.restore")) {
            Task { await restorePurchases() }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.vakitAccent)
        .disabled(isProcessing)
    }

    private var legalLinks: some View {
        HStack(spacing: 14) {
            Link(lang.t("pro.terms"), destination: termsURL)
            Text("·")
            Link(lang.t("pro.privacy"), destination: privacyURL)
        }
        .font(.caption.weight(.semibold))
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

    private func productTitle(for id: PurchaseService.ProductID) -> String {
        switch id {
        case .monthly: return lang.t("pro.monthly")
        case .yearly: return lang.t("pro.yearly")
        case .lifetime: return lang.t("pro.lifetime")
        }
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
        guard !authService.isGuest else {
            errorMessage = lang.t("pro.signInRequired")
            return
        }
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
        .environment(AuthService.shared)
        .environment(PurchaseService.shared)
}

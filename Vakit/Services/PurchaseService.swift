import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class PurchaseService {
    static let shared = PurchaseService()

    static let entitlementIdentifier = "pro"

    enum ProductID: String, CaseIterable {
        case monthly = "vakit_pro_monthly"
        case yearly = "vakit_pro_yearly"
        case lifetime = "vakit_pro_lifetime"
    }

    struct Product: Identifiable, Equatable {
        let id: ProductID
        let localizedPrice: String
    }

    enum ServiceError: Error {
        case notConfigured
        case productUnavailable
    }

    private(set) var hasProAccess = false
    private(set) var products: [Product] = []
    private(set) var isLoading = false

    @ObservationIgnored private var storeProducts: [ProductID: StoreProduct] = [:]

    private init() {}

    func configure() {
        guard !Purchases.isConfigured else { return }
        guard
            let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
            !apiKey.isEmpty,
            !apiKey.contains("$(")
        else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }

    func refresh() async {
        guard Purchases.isConfigured else {
            hasProAccess = false
            products = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        async let customerInfoTask = Purchases.shared.customerInfo()
        async let productsTask = Purchases.shared.products(ProductID.allCases.map(\.rawValue))

        do {
            let customerInfo = try await customerInfoTask
            updateAccess(from: customerInfo)
        } catch {
            hasProAccess = false
        }

        let fetchedProducts = await productsTask
        storeProducts = Dictionary(
            uniqueKeysWithValues: fetchedProducts.compactMap { storeProduct in
                guard let id = ProductID(rawValue: storeProduct.productIdentifier) else { return nil }
                return (id, storeProduct)
            }
        )
        products = ProductID.allCases.compactMap { id in
            storeProducts[id].map { Product(id: id, localizedPrice: $0.localizedPriceString) }
        }
    }

    func purchase(product: Product) async throws {
        guard Purchases.isConfigured else { throw ServiceError.notConfigured }
        guard let storeProduct = storeProducts[product.id] else { throw ServiceError.productUnavailable }

        let result = try await Purchases.shared.purchase(product: storeProduct)
        guard !result.userCancelled else { return }
        updateAccess(from: result.customerInfo)
    }

    func restorePurchases() async throws {
        guard Purchases.isConfigured else { throw ServiceError.notConfigured }
        let customerInfo = try await Purchases.shared.restorePurchases()
        updateAccess(from: customerInfo)
    }

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id }
    }

    private func updateAccess(from customerInfo: CustomerInfo) {
        hasProAccess = customerInfo.entitlements[Self.entitlementIdentifier]?.isActive == true
    }
}

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
        case entitlementNotActive
    }

    #if DEBUG
    /// DEBUG: her zaman Pro aktif (test kolaylığı).
    private(set) var hasProAccess = true
    #else
    private(set) var hasProAccess = false
    #endif
    private(set) var products: [Product] = []
    private(set) var isLoading = false

    @ObservationIgnored private var storeProducts: [ProductID: StoreProduct] = [:]
    @ObservationIgnored private var customerInfoTask: Task<Void, Never>?

    private init() {}

    func configure() {
        if !Purchases.isConfigured {
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

        observeCustomerInfo()
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
            #if !DEBUG
            hasProAccess = false
            #endif
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

        if !hasProAccess {
            let customerInfo = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
            updateAccess(from: customerInfo)
        }

        guard hasProAccess else {
            throw ServiceError.entitlementNotActive
        }
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
        #if !DEBUG
        hasProAccess = customerInfo.entitlements[Self.entitlementIdentifier]?.isActive == true
        #endif
    }

    private func observeCustomerInfo() {
        guard customerInfoTask == nil else { return }

        customerInfoTask = Task { [weak self] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                guard !Task.isCancelled else { return }
                self?.updateAccess(from: customerInfo)
            }
        }
    }
}

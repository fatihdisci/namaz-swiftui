import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class PurchaseService {
    static let shared = PurchaseService()

    static let entitlementIdentifier = "pro"
    static var isInternalTestingBuild: Bool {
        #if DEBUG
        true
        #else
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    enum TestingAccessMode: String, CaseIterable, Identifiable {
        case automatic
        case unlocked
        case locked

        var id: Self { self }
    }

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

    private static let testingAccessModeKey = "pro.testingAccessMode"

    private(set) var entitlementHasProAccess = false
    private(set) var testingAccessMode: TestingAccessMode
    private(set) var products: [Product] = []
    private(set) var isLoading = false

    var hasProAccess: Bool {
        guard Self.isInternalTestingBuild else { return entitlementHasProAccess }

        switch testingAccessMode {
        case .automatic:
            return entitlementHasProAccess
        case .unlocked:
            return true
        case .locked:
            return false
        }
    }

    @ObservationIgnored private var storeProducts: [ProductID: StoreProduct] = [:]
    @ObservationIgnored private var customerInfoTask: Task<Void, Never>?

    private init() {
        if
            let storedValue = UserDefaults.standard.string(forKey: Self.testingAccessModeKey),
            let storedMode = TestingAccessMode(rawValue: storedValue)
        {
            testingAccessMode = storedMode
        } else {
            testingAccessMode = Self.isInternalTestingBuild ? .unlocked : .automatic
        }
    }

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
            entitlementHasProAccess = false
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
            entitlementHasProAccess = false
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

    func setTestingAccessMode(_ mode: TestingAccessMode) {
        guard Self.isInternalTestingBuild else { return }
        testingAccessMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.testingAccessModeKey)
    }

    private func updateAccess(from customerInfo: CustomerInfo) {
        entitlementHasProAccess =
            customerInfo.entitlements[Self.entitlementIdentifier]?.isActive == true
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

import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isPurchased: Bool = UserDefaults.standard.bool(forKey: "isPurchased") {
        didSet {
            UserDefaults.standard.set(isPurchased, forKey: "isPurchased")
        }
    }
    
    private let productDict: [String: String] = [
        "com.moviesapp.premium.monthly": "monthly",
        "com.moviesapp.premium.yearly": "yearly",
        "com.moviesapp.premium.lifetime": "lifetime"
    ]
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: productDict.keys)
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateCustomerProductStatus()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateCustomerProductStatus()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productType == .autoRenewable || transaction.productType == .nonConsumable {
                    purchasedProducts.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify entitlement: \(error)")
            }
        }
        self.purchasedProductIDs = purchasedProducts
        self.isPurchased = !purchasedProducts.isEmpty
    }
    
    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

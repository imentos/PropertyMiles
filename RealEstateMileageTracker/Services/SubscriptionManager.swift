//
//  SubscriptionManager.swift
//  RealEstateMileageTracker
//

import Foundation
import StoreKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    enum ProductID: String, CaseIterable {
        case monthly = "com.landmile.monthly"
        case annual  = "com.landmile.annual"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual:  return "Annual"
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false

    var isPro: Bool { !purchasedProductIDs.isEmpty }

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit { updateListenerTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = ProductID.allCases.map { $0.rawValue }
            let loaded = try await Product.products(for: ids)
            self.products = loaded.sorted { p1, p2 in
                let order = [ProductID.monthly.rawValue, ProductID.annual.rawValue]
                return (order.firstIndex(of: p1.id) ?? 0) < (order.firstIndex(of: p2.id) ?? 1)
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return true
        case .userCancelled: return false
        case .pending:       return false
        @unknown default:    return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.revocationDate == nil {
                active.insert(transaction.productID)
            }
        }
        purchasedProductIDs = active
    }

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { @MainActor in
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.failedVerification
        case .verified(let safe): return safe
        }
    }
}

enum SubscriptionError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Purchase verification failed" }
}

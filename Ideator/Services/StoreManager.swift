import Foundation
import StoreKit
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "StoreManager")

/// Manages in-app purchases for prompt packs using StoreKit 2
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    /// All available products loaded from App Store
    @Published var products: [String: Product] = [:]
    /// Set of pack IDs the user has purchased (or been grandfathered into)
    @Published var purchasedPacks: Set<String> = []
    /// Current purchase in progress
    @Published var purchasingPack: String?
    /// Last purchase error message
    @Published var purchaseError: String?
    /// Cached set of grandfathered pack IDs
    @Published private(set) var grandfatheredPacks: Set<String> = []

    nonisolated private let productIdPrefix = "net.shadowpuppet.ideator.pack."
    private let grandfatheredKey = "grandfatheredPacks"

    /// Pack IDs that are always free (no purchase required)
    private let freePacks: Set<String> = ["core"]

    /// All purchasable pack product IDs (App Store Connect requires periods, not hyphens)
    private let purchasablePackIds: Set<String> = [
        "net.shadowpuppet.ideator.pack.creative.writing",
        "net.shadowpuppet.ideator.pack.disaster.prep",
        "net.shadowpuppet.ideator.pack.family",
        "net.shadowpuppet.ideator.pack.impact.finance",
        "net.shadowpuppet.ideator.pack.silly",
        "net.shadowpuppet.ideator.pack.surreal",
        "net.shadowpuppet.ideator.pack.tech.startup",
        "net.shadowpuppet.ideator.pack.wellness",
    ]

    private var transactionListener: Task<Void, Never>?

    private init() {
        // Load grandfathered packs from UserDefaults
        let grandfathered = UserDefaults.standard.stringArray(forKey: grandfatheredKey) ?? []
        grandfatheredPacks = Set(grandfathered)
        purchasedPacks = grandfatheredPacks.union(freePacks)

        // Start listening for transaction updates (renewals, revocations, etc.)
        transactionListener = listenForTransactions()

        // Load products and verify existing purchases
        Task {
            await loadProducts()
            await refreshPurchaseState()
            logger.info("🛒 init complete: \(self.purchasedPacks.count) purchased packs, \(self.products.count) products loaded")
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public API

    /// Whether a pack is available without purchase (free or purchased/grandfathered)
    func isPurchasedOrFree(_ packId: String) -> Bool {
        freePacks.contains(packId) || purchasedPacks.contains(packId)
    }

    /// Product ID for a given pack ID (converts hyphens to periods for App Store Connect)
    func productId(for packId: String) -> String {
        "\(productIdPrefix)\(packId.replacingOccurrences(of: "-", with: "."))"
    }

    /// Pack ID from a product ID (strips prefix and converts periods back to hyphens)
    nonisolated private func packId(from productID: String) -> String {
        productID
            .replacingOccurrences(of: productIdPrefix, with: "")
            .replacingOccurrences(of: ".", with: "-")
    }

    /// Get the Product for a pack ID (if loaded)
    func product(for packId: String) -> Product? {
        products[productId(for: packId)]
    }

    /// Purchase a pack
    func purchase(_ packId: String) async -> Bool {
        let pid = productId(for: packId)
        guard let product = products[pid] else {
            logger.error("🛒 product not found: \(pid)")
            purchaseError = "Product not available. Please try again later."
            return false
        }

        purchasingPack = packId
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                await transaction.finish()
                purchasedPacks.insert(packId)
                logger.info("🛒 purchased pack: \(packId)")
                purchasingPack = nil
                return true

            case .userCancelled:
                logger.info("🛒 user cancelled purchase: \(packId)")
                purchasingPack = nil
                return false

            case .pending:
                logger.info("🛒 purchase pending: \(packId)")
                purchasingPack = nil
                return false

            @unknown default:
                purchasingPack = nil
                return false
            }
        } catch {
            logger.error("🛒 purchase failed: \(error.localizedDescription)")
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            purchasingPack = nil
            return false
        }
    }

    /// Restore purchases from App Store. Returns true if successful.
    func restorePurchases() async -> Bool {
        logger.info("🛒 restoring purchases...")
        do {
            try await AppStore.sync()
        } catch {
            logger.error("🛒 AppStore.sync() failed: \(error.localizedDescription)")
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
            return false
        }
        let before = purchasedPacks
        await refreshPurchaseState()
        let changed = purchasedPacks != before
        logger.info("🛒 restored \(self.purchasedPacks.count) packs, changed=\(changed)")
        return true
    }

    /// Grandfathers currently installed non-core packs (call once during migration)
    func grandfatherInstalledPacks(_ installedPackIds: [String]) {
        guard grandfatheredPacks.isEmpty else { return }

        let nonCorePacks = installedPackIds.filter { !freePacks.contains($0) }
        guard !nonCorePacks.isEmpty else { return }

        UserDefaults.standard.set(nonCorePacks, forKey: grandfatheredKey)
        grandfatheredPacks = Set(nonCorePacks)
        purchasedPacks.formUnion(nonCorePacks)
        logger.info("🛒 grandfathered \(nonCorePacks.count) packs: \(nonCorePacks.joined(separator: ", "))")
    }

    /// Whether a pack was grandfathered (for UI display)
    func isGrandfathered(_ packId: String) -> Bool {
        grandfatheredPacks.contains(packId)
    }

    // MARK: - Private

    private func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: purchasablePackIds)
            for product in storeProducts {
                products[product.id] = product
            }
            logger.info("🛒 loaded \(storeProducts.count) products")
        } catch {
            logger.error("🛒 failed to load products: \(error.localizedDescription)")
        }
    }

    private func refreshPurchaseState() async {
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)
                purchasedPacks.insert(packId(from: transaction.productID))
            } catch {
                logger.error("🛒 failed to verify transaction: \(error.localizedDescription)")
            }
        }
    }

    /// Listens for transaction updates (renewals, revocations) for the app's lifetime.
    /// Uses [weak self] as a defensive measure, but since StoreManager is a singleton
    /// (accessed via `shared`), self will never be deallocated during normal execution.
    /// The deinit cancels this task as a safety net.
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? Self.checkVerified(result) else { continue }
                let packId = self.packId(from: transaction.productID)

                await MainActor.run {
                    if transaction.revocationDate != nil {
                        self.purchasedPacks.remove(packId)
                    } else {
                        self.purchasedPacks.insert(packId)
                    }
                }

                await transaction.finish()
            }
        }
    }

    nonisolated private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

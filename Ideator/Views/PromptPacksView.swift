import SwiftUI
import StoreKit

struct PromptPacksView: View {
    @StateObject private var packManager = PackManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @State private var showPurchaseError = false

    var body: some View {
        NavigationStack {
            List {
                purchasedPacksSection

                availablePacksSection

                restorePurchasesSection
            }
            .navigationTitle("Prompt Packs")
            .navigationBarTitleDisplayMode(.large)
            .alert("Purchase Failed", isPresented: $showPurchaseError) {
                Button("OK") {}
            } message: {
                Text(storeManager.purchaseError ?? "An unknown error occurred.")
            }
        }
    }

    private var purchasedPacksSection: some View {
        Section("Your Packs") {
            ForEach(packManager.purchasedPacks) { pack in
                PackRow(
                    pack: pack,
                    isPurchased: true,
                    isGrandfathered: storeManager.isGrandfathered(pack.id),
                    onToggle: {
                        packManager.togglePack(pack.id, enabled: !pack.isEnabled)
                        PromptService.shared.reloadPrompts()
                    }
                )
            }
        }
    }

    private var availablePacksSection: some View {
        Section("Available Packs") {
            let unpurchased = packManager.unpurchasedPacks
            if unpurchased.isEmpty {
                Text("All packs are unlocked!")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                ForEach(unpurchased) { pack in
                    PurchasablePackRow(
                        pack: pack,
                        isPurchasing: storeManager.purchasingPack == pack.id,
                        price: storeManager.product(for: pack.id)?.displayPrice,
                        loadState: storeManager.productLoadState,
                        onPurchase: {
                            Task {
                                let success = await storeManager.purchase(pack.id)
                                if success {
                                    PromptService.shared.reloadPrompts()
                                } else if storeManager.purchaseError != nil {
                                    showPurchaseError = true
                                }
                            }
                        },
                        onRetry: {
                            Task {
                                await storeManager.loadProducts()
                            }
                        }
                    )
                }
            }
        }
    }

    private var restorePurchasesSection: some View {
        Section {
            RestorePurchasesButton()
        } footer: {
            Text("Restore previously purchased packs on this device or a new device.")
                .font(.caption2)
        }
    }
}

struct PurchaseButton: View {
    let price: String?
    let loadState: ProductLoadState
    let action: () -> Void
    let onRetry: () -> Void

    var body: some View {
        if let price {
            Button(action: action) {
                Text(price)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(BorderlessButtonStyle())
        } else if loadState == .loading || loadState == .idle {
            ProgressView()
                .scaleEffect(0.7)
        } else if loadState == .failed {
            Button(action: onRetry) {
                Text("Retry")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

struct PurchasingIndicator: View {
    var body: some View {
        VStack(spacing: 2) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Buying...")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct PackStatsView: View {
    let categoryCount: Int
    let promptCount: Int

    var body: some View {
        Label("\(categoryCount) categories", systemImage: "folder")
            .font(.caption2)
            .foregroundColor(.secondary)

        Label("\(promptCount) prompts", systemImage: "lightbulb")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}

struct PackRow: View {
    let pack: PromptPack
    let isPurchased: Bool
    let isGrandfathered: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pack.name)
                            .font(.headline)

                        if isGrandfathered {
                            Text("FREE")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }

                    Text(pack.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { pack.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }

            HStack {
                PackStatsView(categoryCount: pack.categories.count, promptCount: pack.totalPrompts)

                Spacer()

                Text("v\(pack.version)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RestorePurchasesButton: View {
    var onRestore: () async -> Bool = {
        await StoreManager.shared.restorePurchases()
    }
    var onRestoreComplete: () -> Void = {
        PromptService.shared.reloadPrompts()
    }

    @State private var isRestoring = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    @State private var restoreErrorMessage = ""

    var body: some View {
        Button {
            Task {
                isRestoring = true
                let success = await onRestore()
                if success {
                    onRestoreComplete()
                    showRestoreSuccess = true
                } else {
                    restoreErrorMessage = StoreManager.shared.purchaseError ?? "Unable to restore purchases."
                    showRestoreError = true
                }
                isRestoring = false
            }
        } label: {
            HStack(spacing: 6) {
                if isRestoring {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .disabled(isRestoring)
        .alert("Purchases Restored", isPresented: $showRestoreSuccess) {
            Button("OK") {}
        } message: {
            Text("Your purchases have been restored successfully.")
        }
        .alert("Restore Failed", isPresented: $showRestoreError) {
            Button("OK") {}
        } message: {
            Text(restoreErrorMessage)
        }
    }
}

struct PurchasablePackRow: View {
    let pack: PromptPack
    let isPurchasing: Bool
    let price: String?
    let loadState: ProductLoadState
    let onPurchase: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.headline)

                    Text(pack.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isPurchasing {
                    PurchasingIndicator()
                } else {
                    PurchaseButton(price: price, loadState: loadState, action: onPurchase, onRetry: onRetry)
                }
            }

            HStack {
                PackStatsView(categoryCount: pack.categories.count, promptCount: pack.totalPrompts)

                Spacer()

                Text("by \(pack.author)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

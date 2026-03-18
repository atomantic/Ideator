import SwiftUI
import StoreKit

struct PromptPacksView: View {
    @StateObject private var packManager = PackManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @State private var downloadingPacks: Set<String> = []
    @State private var updatingPacks: Set<String> = []
    @State private var showUpdateSuccess = false
    @State private var showUpdateError = false
    @State private var updateErrorMessage = ""
    @State private var showDownloadError = false
    @State private var downloadErrorMessage = ""
    @State private var showPurchaseError = false
    @State private var isRestoringPurchases = false
    @State private var showRestoreSuccess = false

    var body: some View {
        NavigationStack {
            List {
                installedPacksSection

                availablePacksSection

                restorePurchasesSection
            }
            .navigationTitle("Prompt Packs")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await packManager.fetchAvailablePacks()
            }
            .refreshable {
                await packManager.fetchAvailablePacks()
            }
            .alert("Pack Updated", isPresented: $showUpdateSuccess) {
                Button("OK") {}
            } message: {
                Text("The pack has been successfully updated.")
            }
            .alert("Update Failed", isPresented: $showUpdateError) {
                Button("OK") {}
            } message: {
                Text(updateErrorMessage)
            }
            .alert("Download Failed", isPresented: $showDownloadError) {
                Button("OK") {}
            } message: {
                Text(downloadErrorMessage)
            }
            .alert("Purchase Failed", isPresented: $showPurchaseError) {
                Button("OK") {}
            } message: {
                Text(storeManager.purchaseError ?? "An unknown error occurred.")
            }
            .alert("Purchases Restored", isPresented: $showRestoreSuccess) {
                Button("OK") {}
            } message: {
                Text("Your purchases have been restored successfully.")
            }
        }
    }

    private func purchaseIfNeeded(_ packId: String) async -> Bool {
        if !storeManager.isPurchasedOrFree(packId) {
            let success = await storeManager.purchase(packId)
            guard success else {
                if storeManager.purchaseError != nil {
                    showPurchaseError = true
                }
                return false
            }
        }
        return true
    }

    private var installedPacksSection: some View {
        Section("Installed Packs") {
            ForEach(packManager.installedPacks) { pack in
                PackRow(
                    pack: pack,
                    isUpdating: updatingPacks.contains(pack.id),
                    updateAvailable: packManager.packUpdates[pack.id],
                    isPurchased: storeManager.isPurchasedOrFree(pack.id),
                    isGrandfathered: storeManager.isGrandfathered(pack.id),
                    onToggle: {
                        packManager.togglePack(pack.id, enabled: !pack.isEnabled)
                        PromptService.shared.reloadPrompts()
                    },
                    onUpdate: {
                        Task {
                            guard await purchaseIfNeeded(pack.id) else { return }

                            updatingPacks.insert(pack.id)
                            do {
                                try await packManager.updatePack(pack.id)
                                packManager.loadInstalledPacks()
                                await packManager.fetchAvailablePacks()
                                PromptService.shared.reloadPrompts()
                                showUpdateSuccess = true
                            } catch {
                                updateErrorMessage = "Failed to update \(pack.name): \(error.localizedDescription)"
                                showUpdateError = true
                            }
                            updatingPacks.remove(pack.id)
                        }
                    }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let pack = packManager.installedPacks[index]
                    if pack.id != "core" {
                        packManager.deletePack(pack.id)
                        PromptService.shared.reloadPrompts()
                    }
                }
            }
        }
    }

    private var availablePacksSection: some View {
        Section("Available Packs") {
            if packManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading available packs...")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if packManager.availablePacks.isEmpty {
                Text("All packs are already installed")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                ForEach(packManager.availablePacks, id: \.id) { packInfo in
                    RemotePackRow(
                        packInfo: packInfo,
                        isDownloading: downloadingPacks.contains(packInfo.id),
                        isPurchasing: storeManager.purchasingPack == packInfo.id,
                        price: storeManager.product(for: packInfo.id)?.displayPrice,
                        onPurchaseAndDownload: {
                            Task {
                                guard await purchaseIfNeeded(packInfo.id) else { return }

                                downloadingPacks.insert(packInfo.id)
                                do {
                                    try await packManager.downloadPack(packInfo)
                                    PromptService.shared.reloadPrompts()
                                    await packManager.fetchAvailablePacks()
                                } catch {
                                    downloadErrorMessage = "Failed to download \(packInfo.name): \(error.localizedDescription)"
                                    showDownloadError = true
                                }
                                downloadingPacks.remove(packInfo.id)
                            }
                        }
                    )
                }
            }
        }
    }

    private var restorePurchasesSection: some View {
        Section {
            Button {
                Task {
                    isRestoringPurchases = true
                    await storeManager.restorePurchases()
                    isRestoringPurchases = false
                    showRestoreSuccess = true
                }
            } label: {
                HStack {
                    if isRestoringPurchases {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Restore Purchases")
                }
            }
            .disabled(isRestoringPurchases)
        } footer: {
            Text("Restore previously purchased packs on this device or a new device.")
                .font(.caption2)
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
    let isUpdating: Bool
    let updateAvailable: String?
    let isPurchased: Bool
    let isGrandfathered: Bool
    let onToggle: () -> Void
    let onUpdate: () -> Void

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

                if let newVersion = updateAvailable {
                    if !isPurchased {
                        // Update available but not purchased — show purchase prompt
                        Button(action: onUpdate) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                Text("Purchase to Update")
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    } else if isUpdating {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Button(action: onUpdate) {
                            HStack(spacing: 4) {
                                Text("v\(pack.version)")
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                Text("v\(newVersion)")
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                } else {
                    HStack(spacing: 4) {
                        Text("v\(pack.version)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}


struct RemotePackRow: View {
    let packInfo: RemotePackInfo
    let isDownloading: Bool
    let isPurchasing: Bool
    let price: String?
    let onPurchaseAndDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(packInfo.name)
                        .font(.headline)

                    Text(packInfo.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isDownloading || isPurchasing {
                    VStack(spacing: 2) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(isPurchasing ? "Buying..." : "Installing...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: onPurchaseAndDownload) {
                        Text(price ?? "$0.99")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            HStack {
                PackStatsView(categoryCount: packInfo.categories.count, promptCount: packInfo.promptCount)

                Spacer()

                Text("by \(packInfo.author)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

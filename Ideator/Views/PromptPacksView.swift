import SwiftUI

struct PromptPacksView: View {
    @StateObject private var packManager = PackManager.shared
    @State private var downloadingPacks: Set<String> = []
    @State private var updatingPacks: Set<String> = []
    @State private var showUpdateSuccess = false
    @State private var showUpdateError = false
    @State private var updateErrorMessage = ""
    @State private var showDownloadError = false
    @State private var downloadErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                installedPacksSection
                
                availablePacksSection
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
                Text("The pack has been successfully updated from GitHub.")
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
        }
    }
    
    private var installedPacksSection: some View {
        Section("Installed Packs") {
            ForEach(packManager.installedPacks) { pack in
                PackRow(
                    pack: pack,
                    isUpdating: updatingPacks.contains(pack.id),
                    onToggle: {
                        packManager.togglePack(pack.id, enabled: !pack.isEnabled)
                        // Reload prompts when toggling packs
                        PromptService.shared.reloadPrompts()
                    },
                    onUpdate: {
                        Task {
                            updatingPacks.insert(pack.id)
                            do {
                                try await packManager.updatePack(pack.id)
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
                    if pack.id != "core" { // Don't allow deleting core pack
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
                        onDownload: {
                            Task {
                                downloadingPacks.insert(packInfo.id)
                                do {
                                    try await packManager.downloadPack(packInfo)
                                    PromptService.shared.reloadPrompts()
                                    // Refresh available packs to remove downloaded one
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
}

struct PackRow: View {
    let pack: PromptPack
    let isUpdating: Bool
    let onToggle: () -> Void
    let onUpdate: () -> Void
    
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
                
                Toggle("", isOn: Binding(
                    get: { pack.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            HStack {
                Label("\(pack.categories.count) categories", systemImage: "folder")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Label("\(pack.totalPrompts) prompts", systemImage: "lightbulb")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isUpdating {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button(action: onUpdate) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                if pack.id == "core" {
                    Text("Built-in")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                } else {
                    Text("v\(pack.version)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}


struct RemotePackRow: View {
    let packInfo: RemotePackInfo
    let isDownloading: Bool
    let onDownload: () -> Void
    
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
                
                if isDownloading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: onDownload) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            HStack {
                Label("\(packInfo.categories.count) categories", systemImage: "folder")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Label("\(packInfo.promptCount) prompts", systemImage: "lightbulb")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("by \(packInfo.author)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
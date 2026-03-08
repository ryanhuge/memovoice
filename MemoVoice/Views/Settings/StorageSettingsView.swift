import SwiftUI

struct StorageSettingsView: View {
    @State private var audioSize: String = "..."
    @State private var ttsSize: String = "..."
    @State private var modelsSize: String = "..."
    @State private var isCleaningAudio = false
    @State private var isCleaningTTS = false
    @State private var isCleaningModels = false
    @State private var showConfirmDeleteModels = false

    var body: some View {
        Form {
            Section {
                storageRow(
                    title: String(localized: "Extracted Audio"),
                    subtitle: String(localized: "FFmpeg extracted WAV, YouTube downloads"),
                    size: audioSize,
                    isCleaning: isCleaningAudio
                ) {
                    isCleaningAudio = true
                    clearDirectory(FileManager.default.audioDirectory)
                    refreshSizes()
                    isCleaningAudio = false
                }

                storageRow(
                    title: String(localized: "TTS Cache"),
                    subtitle: String(localized: "Text-to-speech generated audio"),
                    size: ttsSize,
                    isCleaning: isCleaningTTS
                ) {
                    isCleaningTTS = true
                    clearDirectory(FileManager.default.ttsOutputDirectory)
                    refreshSizes()
                    isCleaningTTS = false
                }

                storageRow(
                    title: String(localized: "Whisper Models"),
                    subtitle: String(localized: "Downloaded speech recognition models"),
                    size: modelsSize,
                    isCleaning: isCleaningModels
                ) {
                    showConfirmDeleteModels = true
                }
            } header: {
                Text("Storage Usage")
            }

            Section {
                Button(role: .destructive) {
                    isCleaningAudio = true
                    isCleaningTTS = true
                    clearDirectory(FileManager.default.audioDirectory)
                    clearDirectory(FileManager.default.ttsOutputDirectory)
                    refreshSizes()
                    isCleaningAudio = false
                    isCleaningTTS = false
                } label: {
                    Label(String(localized: "Clean All Cache"), systemImage: "trash")
                }
                .help("Clean extracted audio and TTS cache (keeps models)")
            } header: {
                Text("Quick Actions")
            }
        }
        .formStyle(.grouped)
        .onAppear { refreshSizes() }
        .alert(String(localized: "Delete All Models?"), isPresented: $showConfirmDeleteModels) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Delete"), role: .destructive) {
                isCleaningModels = true
                clearDirectory(FileManager.default.modelsDirectory)
                clearWhisperKitCache()
                refreshSizes()
                isCleaningModels = false
            }
        } message: {
            Text("Models will need to be re-downloaded before next transcription.")
        }
    }

    private func storageRow(
        title: String,
        subtitle: String,
        size: String,
        isCleaning: Bool,
        onClean: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(size)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)

            Button {
                onClean()
            } label: {
                if isCleaning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "trash")
                }
            }
            .buttonStyle(.borderless)
            .disabled(isCleaning)
        }
    }

    private func refreshSizes() {
        audioSize = directorySize(FileManager.default.audioDirectory)
        ttsSize = directorySize(FileManager.default.ttsOutputDirectory)
        modelsSize = directorySize(FileManager.default.modelsDirectory)

        // Also check WhisperKit's default cache location
        let whisperCacheURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/huggingface/models/argmaxinc/whisperkit-coreml")
        if FileManager.default.fileExists(atPath: whisperCacheURL.path) {
            let extraSize = directorySize(whisperCacheURL)
            if modelsSize == "0 B" {
                modelsSize = extraSize
            } else {
                modelsSize = "\(modelsSize) + \(extraSize)"
            }
        }
    }

    private func directorySize(_ url: URL) -> String {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 B"
        }

        var totalBytes: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = values.fileSize {
                totalBytes += Int64(size)
            }
        }

        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    private func clearDirectory(_ url: URL) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return }
        for item in contents {
            try? fm.removeItem(at: item)
        }
    }

    private func clearWhisperKitCache() {
        let whisperCacheURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/huggingface/models/argmaxinc/whisperkit-coreml")
        clearDirectory(whisperCacheURL)

        // Clear UserDefaults cached model paths
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix("WhisperModelFolder_") {
            defaults.removeObject(forKey: key)
        }

        // Reset WhisperService state
        Task { @MainActor in
            WhisperService.shared.isModelLoaded = false
        }
    }
}

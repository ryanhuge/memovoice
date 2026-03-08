import Foundation
import WhisperKit
import CoreML
import os

/// Thread-safe flags for controlling transcription from @Sendable callbacks
final class TranscriptionControl: Sendable {
    private let _isPaused = OSAllocatedUnfairLock(initialState: false)
    private let _isCancelled = OSAllocatedUnfairLock(initialState: false)

    var isPaused: Bool {
        get { _isPaused.withLock { $0 } }
        set { _isPaused.withLock { $0 = newValue } }
    }

    var isCancelled: Bool {
        get { _isCancelled.withLock { $0 } }
        set { _isCancelled.withLock { $0 = newValue } }
    }

    func reset() {
        isPaused = false
        isCancelled = false
    }
}

@Observable
@MainActor
final class WhisperService {
    static let shared = WhisperService()

    var isModelLoaded = false
    var isPaused = false
    var isCancelled = false

    let control = TranscriptionControl()

    private var whisperKit: WhisperKit?
    private var loadedModelName: String?

    /// UserDefaults key prefix for cached model folder paths
    private static let modelFolderKeyPrefix = "WhisperModelFolder_"

    private init() {}

    enum WhisperError: LocalizedError {
        case modelNotLoaded
        case transcriptionFailed(String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                "Whisper model is not loaded. Please download a model first."
            case .transcriptionFailed(let msg):
                "Transcription failed: \(msg)"
            case .cancelled:
                "Transcription was cancelled."
            }
        }
    }

    func pauseTranscription() {
        isPaused = true
        control.isPaused = true
    }

    func resumeTranscription() {
        isPaused = false
        control.isPaused = false
    }

    func cancelTranscription() {
        isCancelled = true
        isPaused = false
        control.isCancelled = true
        control.isPaused = false
    }

    /// Download and load a model with progress reporting.
    /// Skips download if the model is already cached on disk,
    /// and skips initialization if the same model is already loaded in memory.
    func loadModel(
        _ modelName: String,
        onProgress: @escaping @Sendable (String, Double) -> Void
    ) async throws {
        // Already loaded in memory with the same model → skip entirely
        if isModelLoaded, loadedModelName == modelName, whisperKit != nil {
            onProgress(String(localized: "Model ready."), 1.0)
            return
        }

        // If switching models, release the old one
        if loadedModelName != nil && loadedModelName != modelName {
            whisperKit = nil
            isModelLoaded = false
            loadedModelName = nil
        }

        // Check if model was previously downloaded and still exists on disk
        let cacheKey = Self.modelFolderKeyPrefix + modelName
        let cachedPath = UserDefaults.standard.string(forKey: cacheKey)

        let modelFolder: String

        if let cachedPath, FileManager.default.fileExists(atPath: cachedPath) {
            // Model files exist on disk — skip download
            onProgress(String(localized: "Loading model from cache..."), 0.5)
            modelFolder = cachedPath
        } else {
            // Need to download
            onProgress(String(localized: "Downloading model..."), 0)
            let folderURL = try await WhisperKit.download(variant: modelName) { @Sendable progress in
                onProgress(
                    String(localized: "Downloading model... \(Int(progress.fractionCompleted * 100))%"),
                    progress.fractionCompleted
                )
            }
            modelFolder = folderURL.path
            // Cache the path for next time
            UserDefaults.standard.set(modelFolder, forKey: cacheKey)
        }

        onProgress(String(localized: "Loading model..."), 1.0)

        // Load WhisperKit with all compute units (CPU + GPU + Neural Engine)
        let computeOptions = ModelComputeOptions(
            audioEncoderCompute: .all,
            textDecoderCompute: .all
        )
        let config = WhisperKitConfig(
            modelFolder: modelFolder,
            computeOptions: computeOptions,
            download: false
        )
        whisperKit = try await WhisperKit(config)
        loadedModelName = modelName
        isModelLoaded = true
    }

    /// Preload the default model at app startup so it's ready when needed
    func preloadDefaultModel() {
        let modelName = AppState.shared.selectedModel
        guard !isModelLoaded || loadedModelName != modelName else { return }
        Task {
            try? await loadModel(modelName) { _, _ in }
        }
    }

    /// Check if a model has been downloaded to disk
    func isModelDownloaded(_ modelName: String) -> Bool {
        let cacheKey = Self.modelFolderKeyPrefix + modelName
        guard let cachedPath = UserDefaults.standard.string(forKey: cacheKey) else {
            return false
        }
        return FileManager.default.fileExists(atPath: cachedPath)
    }

    /// Get the cached folder path for a model
    func modelFolderPath(_ modelName: String) -> String? {
        let cacheKey = Self.modelFolderKeyPrefix + modelName
        guard let cachedPath = UserDefaults.standard.string(forKey: cacheKey),
              FileManager.default.fileExists(atPath: cachedPath) else {
            return nil
        }
        return cachedPath
    }

    /// Delete a single model from disk
    func deleteModel(_ modelName: String) {
        let cacheKey = Self.modelFolderKeyPrefix + modelName
        if let cachedPath = UserDefaults.standard.string(forKey: cacheKey) {
            try? FileManager.default.removeItem(atPath: cachedPath)
        }
        UserDefaults.standard.removeObject(forKey: cacheKey)

        // If we just deleted the currently loaded model, unload it
        if loadedModelName == modelName {
            whisperKit = nil
            isModelLoaded = false
            loadedModelName = nil
        }
    }

    /// Transcribe an audio file with real-time progress via WhisperKit callback.
    /// Supports pause/resume and cancellation.
    func transcribe(
        audioURL: URL,
        language: String? = nil,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> [TranscriptionSegment] {
        guard let whisperKit else {
            throw WhisperError.modelNotLoaded
        }

        // Reset control flags
        isPaused = false
        isCancelled = false
        control.reset()

        nonisolated(unsafe) let kit = whisperKit
        let ctl = control

        let options = DecodingOptions(
            language: language,
            usePrefillPrompt: true,
            usePrefillCache: true,
            wordTimestamps: false,
            concurrentWorkerCount: 4,
            chunkingStrategy: .vad
        )

        nonisolated(unsafe) let progressRef = onProgress
        let results = try await kit.transcribe(
            audioPath: audioURL.path,
            decodeOptions: options
        ) { @Sendable _ in
            // Cancel: return false to stop transcription
            if ctl.isCancelled {
                return false
            }

            // Pause: block until resumed
            while ctl.isPaused && !ctl.isCancelled {
                Thread.sleep(forTimeInterval: 0.1)
            }

            if ctl.isCancelled {
                return false
            }

            // Report progress
            let fraction = kit.progress.fractionCompleted
            progressRef(fraction)
            return nil // nil = continue transcription
        }

        // Check if cancelled after transcription returns
        if control.isCancelled {
            throw WhisperError.cancelled
        }

        var segments: [TranscriptionSegment] = []
        for result in results {
            for segment in result.segments {
                let seg = TranscriptionSegment(
                    index: segments.count,
                    startTime: Double(segment.start),
                    endTime: Double(segment.end),
                    text: segment.text.trimmingCharacters(in: .whitespaces),
                    confidence: segment.avgLogprob
                )
                segments.append(seg)
            }
        }

        return segments
    }
}

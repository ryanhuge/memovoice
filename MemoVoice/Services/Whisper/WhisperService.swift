import Foundation
import WhisperKit

@Observable
@MainActor
final class WhisperService {
    static let shared = WhisperService()

    var isModelLoaded = false

    private var whisperKit: WhisperKit?
    private var loadedModelName: String?

    /// UserDefaults key prefix for cached model folder paths
    private static let modelFolderKeyPrefix = "WhisperModelFolder_"

    private init() {}

    enum WhisperError: LocalizedError {
        case modelNotLoaded
        case transcriptionFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                "Whisper model is not loaded. Please download a model first."
            case .transcriptionFailed(let msg):
                "Transcription failed: \(msg)"
            }
        }
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

        // Load WhisperKit from the model folder (skip re-download)
        let config = WhisperKitConfig(modelFolder: modelFolder, download: false)
        whisperKit = try await WhisperKit(config)
        loadedModelName = modelName
        isModelLoaded = true
    }

    /// Check if a model has been downloaded to disk
    func isModelDownloaded(_ modelName: String) -> Bool {
        let cacheKey = Self.modelFolderKeyPrefix + modelName
        guard let cachedPath = UserDefaults.standard.string(forKey: cacheKey) else {
            return false
        }
        return FileManager.default.fileExists(atPath: cachedPath)
    }

    /// Transcribe an audio file with real-time progress via WhisperKit callback
    func transcribe(
        audioURL: URL,
        language: String? = nil,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> [TranscriptionSegment] {
        guard let whisperKit else {
            throw WhisperError.modelNotLoaded
        }

        nonisolated(unsafe) let kit = whisperKit

        let options = DecodingOptions(
            language: language,
            wordTimestamps: true,
            chunkingStrategy: .vad
        )

        nonisolated(unsafe) let progressRef = onProgress
        let results = try await kit.transcribe(
            audioPath: audioURL.path,
            decodeOptions: options
        ) { @Sendable _ in
            // Report progress from WhisperKit's internal Progress object
            let fraction = kit.progress.fractionCompleted
            progressRef(fraction)
            return nil // nil = continue transcription
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

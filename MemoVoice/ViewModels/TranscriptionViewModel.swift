import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class TranscriptionViewModel {
    var isTranscribing = false
    var isPaused = false
    var transcriptionProgress: Double = 0
    var statusMessage = ""
    var errorMessage: String?

    private let whisperService = WhisperService.shared
    private let ffmpegService = FFmpegService()

    func pauseTranscription() {
        isPaused = true
        whisperService.pauseTranscription()
        statusMessage = String(localized: "Paused")
    }

    func resumeTranscription() {
        isPaused = false
        whisperService.resumeTranscription()
        statusMessage = String(localized: "Transcribing...")
    }

    func cancelTranscription() {
        isPaused = false
        whisperService.cancelTranscription()
    }

    /// Start the full transcription pipeline for a project
    func startTranscription(project: TranscriptionProject, modelContext: ModelContext) async {
        isTranscribing = true
        transcriptionProgress = 0
        statusMessage = String(localized: "Preparing...")
        errorMessage = nil

        do {
            // Step 1: Resolve audio URL
            let audioURL: URL
            switch project.sourceType {
            case .audioFile:
                guard let url = project.sourceURL else {
                    throw TranscriptionError.noSourceFile
                }
                audioURL = url

            case .videoFile:
                guard let videoURL = project.sourceURL else {
                    throw TranscriptionError.noSourceFile
                }
                statusMessage = String(localized: "Extracting audio...")
                project.status = .extractingAudio
                let outputURL = FileManager.default.audioDirectory
                    .appendingPathComponent("\(project.id.uuidString).wav")
                try await ffmpegService.extractAudio(from: videoURL, to: outputURL)
                audioURL = outputURL

            case .youtubeURL:
                guard let ytURL = project.sourceURL else {
                    throw TranscriptionError.noSourceFile
                }
                statusMessage = String(localized: "Fetching video info...")
                project.status = .importing
                let ytdlpService = YTDLPService()

                // Fetch video title and update project
                if let title = try? await ytdlpService.getVideoTitle(from: ytURL), !title.isEmpty {
                    project.title = title
                }

                statusMessage = String(localized: "Downloading from YouTube...")
                let downloadDir = FileManager.default.audioDirectory
                audioURL = try await ytdlpService.downloadAudio(
                    from: ytURL,
                    to: downloadDir
                ) { _, _ in }
            }

            // Step 2: Get audio duration
            let duration = try await AudioChunker.getAudioDuration(url: audioURL)
            project.audioDuration = duration

            // Step 3: Download & load Whisper model (0% → 10% of total progress)
            project.status = .transcribing
            nonisolated(unsafe) let unsafeProject = project

            try await whisperService.loadModel(project.modelName) { [weak self] message, progress in
                Task { @MainActor in
                    self?.statusMessage = message
                    let overall = progress * 0.1
                    self?.transcriptionProgress = overall
                    unsafeProject.progress = overall
                }
            }

            // Step 4: Transcribe with real-time progress (10% → 95%)
            statusMessage = String(localized: "Transcribing...")

            let segments = try await whisperService.transcribe(
                audioURL: audioURL,
                language: project.language
            ) { [weak self] fraction in
                Task { @MainActor in
                    let overall = 0.1 + fraction * 0.85
                    self?.transcriptionProgress = overall
                    unsafeProject.progress = overall
                }
            }

            // Step 5: Save segments to project
            statusMessage = String(localized: "Saving results...")
            for segment in segments {
                segment.project = project
                modelContext.insert(segment)
            }
            project.status = .completed
            project.progress = 1.0
            project.updatedAt = Date()
            try? modelContext.save()

        } catch WhisperService.WhisperError.cancelled {
            // User cancelled — reset to importable state
            project.status = .importing
            project.progress = 0
            statusMessage = String(localized: "Cancelled")
            try? modelContext.save()
        } catch {
            project.status = .failed
            project.errorMessage = error.localizedDescription
            errorMessage = error.localizedDescription
            try? modelContext.save()
        }

        isTranscribing = false
        isPaused = false
    }

    enum TranscriptionError: LocalizedError {
        case noSourceFile

        var errorDescription: String? {
            switch self {
            case .noSourceFile:
                String(localized: "No source file specified for this project.")
            }
        }
    }
}

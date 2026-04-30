import Foundation

final class FFmpegService: Sendable {
    private let ffmpegPath: String

    enum FFmpegError: LocalizedError {
        case notInstalled
        case extractionFailed(String)

        var errorDescription: String? {
            switch self {
            case .notInstalled:
                "FFmpeg is not installed. Please install it via Settings > Tools."
            case .extractionFailed(let msg):
                "Audio extraction failed: \(msg)"
            }
        }
    }

    init(ffmpegPath: String = AppState.shared.ffmpegPath) {
        self.ffmpegPath = ffmpegPath
    }

    /// Extract audio from video file as 16kHz mono WAV (required by Whisper)
    func extractAudio(
        from videoURL: URL,
        to outputURL: URL,
        progressCallback: @escaping @Sendable (String) -> Void = { _ in }
    ) async throws {
        guard FileManager.default.isExecutableFile(atPath: ffmpegPath) else {
            throw FFmpegError.notInstalled
        }

        // Remove existing output file if present
        try? FileManager.default.removeItem(at: outputURL)

        let result = try await ProcessRunner.run(
            executablePath: ffmpegPath,
            arguments: [
                "-i", videoURL.path,
                "-vn",                      // No video
                "-acodec", "pcm_s16le",     // 16-bit PCM
                "-ar", "16000",             // 16kHz sample rate
                "-ac", "1",                 // Mono
                "-y",                       // Overwrite
                outputURL.path
            ]
        )

        guard result.isSuccess else {
            throw FFmpegError.extractionFailed(result.stderr)
        }
    }

    /// Convert any audio format to 16kHz mono WAV
    func convertToWav(
        from inputURL: URL,
        to outputURL: URL
    ) async throws {
        guard FileManager.default.isExecutableFile(atPath: ffmpegPath) else {
            throw FFmpegError.notInstalled
        }

        try? FileManager.default.removeItem(at: outputURL)

        let result = try await ProcessRunner.run(
            executablePath: ffmpegPath,
            arguments: [
                "-i", inputURL.path,
                "-acodec", "pcm_s16le",
                "-ar", "16000",
                "-ac", "1",
                "-y",
                outputURL.path
            ]
        )

        guard result.isSuccess else {
            throw FFmpegError.extractionFailed(result.stderr)
        }
    }
}

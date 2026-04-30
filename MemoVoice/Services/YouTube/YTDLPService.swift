import Foundation

final class YTDLPService {
    private let ytdlpPath: String

    enum YTDLPError: LocalizedError {
        case notInstalled
        case downloadFailed(String)
        case outputFileNotFound

        var errorDescription: String? {
            switch self {
            case .notInstalled:
                "yt-dlp is not installed. Please install it via Settings > Tools."
            case .downloadFailed(let msg):
                "YouTube download failed: \(msg)"
            case .outputFileNotFound:
                "Downloaded file not found."
            }
        }
    }

    init(ytdlpPath: String = AppState.shared.ytdlpPath) {
        self.ytdlpPath = ytdlpPath
    }

    /// Download audio from a YouTube URL
    func downloadAudio(
        from url: URL,
        to outputDirectory: URL,
        progressCallback: @escaping @Sendable (Double, String) -> Void
    ) async throws -> URL {
        guard FileManager.default.isExecutableFile(atPath: ytdlpPath) else {
            throw YTDLPError.notInstalled
        }

        progressCallback(0.05, "Starting YouTube download...")

        let outputTemplate = outputDirectory
            .appendingPathComponent("%(title)s.%(ext)s").path

        let result = try await ProcessRunner.run(
            executablePath: ytdlpPath,
            arguments: [
                "--extract-audio",
                "--audio-format", "wav",
                "--audio-quality", "0",
                "--output", outputTemplate,
                "--no-playlist",
                "--restrict-filenames",
                url.absoluteString
            ],
            timeout: 600
        )

        guard result.isSuccess else {
            throw YTDLPError.downloadFailed(result.stderr)
        }

        progressCallback(0.9, "Locating downloaded audio...")

        // Find the downloaded file
        let files = try FileManager.default.contentsOfDirectory(
            at: outputDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )

        guard let newestFile = files
            .filter({ $0.pathExtension == "wav" })
            .sorted(by: { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return date1 > date2
            })
            .first else {
            throw YTDLPError.outputFileNotFound
        }

        progressCallback(1.0, "Download complete.")
        return newestFile
    }

    /// Get video title without downloading
    func getVideoTitle(from url: URL) async throws -> String {
        guard FileManager.default.isExecutableFile(atPath: ytdlpPath) else {
            throw YTDLPError.notInstalled
        }

        let result = try await ProcessRunner.run(
            executablePath: ytdlpPath,
            arguments: [
                "--get-title",
                "--no-warnings",
                url.absoluteString
            ],
            timeout: 30
        )

        guard result.isSuccess else {
            throw YTDLPError.downloadFailed(result.stderr)
        }

        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

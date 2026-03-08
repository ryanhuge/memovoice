import Foundation
import Observation

@Observable
@MainActor
final class ImportViewModel {
    var isImporting = false
    var importProgress: Double = 0
    var statusText = ""
    var errorMessage: String?

    /// Fetch YouTube video title for preview
    func fetchYouTubeTitle(url: URL) async -> String? {
        let service = YTDLPService()
        return try? await service.getVideoTitle(from: url)
    }

    /// Check if required tools are available for the given source type
    func checkToolAvailability(for sourceType: TranscriptionProject.SourceType) -> (available: Bool, missingTool: String?) {
        switch sourceType {
        case .audioFile:
            return (true, nil)
        case .videoFile:
            let ffmpegAvailable = FileManager.default.isExecutableFile(atPath: AppState.shared.ffmpegPath)
            return (ffmpegAvailable, ffmpegAvailable ? nil : "FFmpeg")
        case .youtubeURL:
            let ytdlpAvailable = FileManager.default.isExecutableFile(atPath: AppState.shared.ytdlpPath)
            return (ytdlpAvailable, ytdlpAvailable ? nil : "yt-dlp")
        }
    }
}

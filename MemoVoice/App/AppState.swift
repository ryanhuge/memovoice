import SwiftUI

final class AppState: @unchecked Sendable {
    static let shared = AppState()

    // External tool paths
    var ffmpegPath: String {
        get { UserDefaults.standard.string(forKey: "ffmpegPath") ?? "/opt/homebrew/bin/ffmpeg" }
        set { UserDefaults.standard.set(newValue, forKey: "ffmpegPath") }
    }

    var ytdlpPath: String {
        get { UserDefaults.standard.string(forKey: "ytdlpPath") ?? "/opt/homebrew/bin/yt-dlp" }
        set { UserDefaults.standard.set(newValue, forKey: "ytdlpPath") }
    }

    var claudePath: String {
        get { UserDefaults.standard.string(forKey: "claudePath") ?? "/opt/homebrew/bin/claude" }
        set { UserDefaults.standard.set(newValue, forKey: "claudePath") }
    }

    // Whisper settings
    var selectedModel: String {
        get { UserDefaults.standard.string(forKey: "selectedModel") ?? "large-v3_turbo" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedModel") }
    }

    var chunkDuration: Double {
        get {
            let val = UserDefaults.standard.double(forKey: "chunkDuration")
            return val > 0 ? val : 30.0
        }
        set { UserDefaults.standard.set(newValue, forKey: "chunkDuration") }
    }

    var overlapDuration: Double {
        get {
            let val = UserDefaults.standard.double(forKey: "overlapDuration")
            return val > 0 ? val : 2.0
        }
        set { UserDefaults.standard.set(newValue, forKey: "overlapDuration") }
    }

    // Translation settings
    var translationProvider: String {
        get { UserDefaults.standard.string(forKey: "translationProvider") ?? "claude-cli" }
        set { UserDefaults.standard.set(newValue, forKey: "translationProvider") }
    }

    var targetLanguage: String {
        get { UserDefaults.standard.string(forKey: "targetLanguage") ?? "zh-TW" }
        set { UserDefaults.standard.set(newValue, forKey: "targetLanguage") }
    }

    // TTS settings
    var ttsProvider: String {
        get { UserDefaults.standard.string(forKey: "ttsProvider") ?? "edge-tts" }
        set { UserDefaults.standard.set(newValue, forKey: "ttsProvider") }
    }

    private init() {}
}

struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

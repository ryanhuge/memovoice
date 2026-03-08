import Foundation

enum TTSProvider: String, CaseIterable, Identifiable {
    case systemTTS = "system"
    case edgeTTS = "edge-tts"
    case fishAudio = "fish-audio"
    case miniMax = "minimax"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .systemTTS: String(localized: "System (macOS)")
        case .edgeTTS: String(localized: "Edge TTS")
        case .fishAudio: String(localized: "Fish Audio")
        case .miniMax: String(localized: "MiniMax")
        }
    }

    var icon: String {
        switch self {
        case .systemTTS: "desktopcomputer"
        case .edgeTTS: "speaker.wave.3"
        case .fishAudio: "fish"
        case .miniMax: "waveform.circle"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .systemTTS, .edgeTTS: false
        case .fishAudio, .miniMax: true
        }
    }

    var keychainKey: String {
        "com.memovoice.ttskey.\(rawValue)"
    }
}

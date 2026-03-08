import Foundation

protocol TTSServiceProtocol: Sendable {
    func speak(
        text: String,
        voice: String,
        outputURL: URL
    ) async throws
}

enum TTSError: LocalizedError {
    case providerNotConfigured(String)
    case synthesizeFailed(String)
    case voiceNotFound(String)

    var errorDescription: String? {
        switch self {
        case .providerNotConfigured(let provider):
            "\(provider) is not configured. Please set your API key in Settings."
        case .synthesizeFailed(let msg):
            "Speech synthesis failed: \(msg)"
        case .voiceNotFound(let voice):
            "Voice '\(voice)' not found."
        }
    }
}

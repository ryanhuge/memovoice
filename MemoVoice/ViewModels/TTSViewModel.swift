import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class TTSViewModel: NSObject, AVSpeechSynthesizerDelegate {
    var isSpeaking = false
    var errorMessage: String?

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var speakingTask: Task<Void, Never>?
    private var speechContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(
        text: String,
        provider: TTSProvider,
        voice: String
    ) {
        stop()
        isSpeaking = true
        errorMessage = nil

        if provider == .systemTTS {
            speakWithSystemTTS(text: text, voice: voice)
        } else {
            speakWithExternalProvider(text: text, provider: provider, voice: voice)
        }
    }

    func stop() {
        speakingTask?.cancel()
        speakingTask = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        speechContinuation?.resume()
        speechContinuation = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }

    // MARK: - System TTS using AVSpeechSynthesizer

    private func speakWithSystemTTS(text: String, voice: String) {
        // Sanitize text: strip XML/SSML characters that cause SSMLParserError
        let sanitized = text
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&", with: " and ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else {
            errorMessage = String(localized: "No speakable text.")
            isSpeaking = false
            return
        }

        let utterance = AVSpeechUtterance(string: sanitized)

        // Resolve voice
        if let avVoice = resolveAVVoice(voice) {
            utterance.voice = avVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1

        speakingTask = Task {
            await withCheckedContinuation { continuation in
                self.speechContinuation = continuation
                self.synthesizer.speak(utterance)
            }
            isSpeaking = false
        }
    }

    private func resolveAVVoice(_ voiceID: String) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // Exact match by identifier
        if let match = allVoices.first(where: { $0.identifier == voiceID }) {
            return match
        }

        // Match by name
        if let match = allVoices.first(where: { $0.name.localizedCaseInsensitiveContains(voiceID) }) {
            return match
        }

        // Match by language prefix (e.g., "en", "zh-TW")
        if let match = allVoices.first(where: { $0.language.hasPrefix(voiceID) }) {
            return match
        }

        return nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            speechContinuation?.resume()
            speechContinuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            speechContinuation?.resume()
            speechContinuation = nil
        }
    }

    // MARK: - External providers (Edge TTS, Fish Audio, MiniMax)

    private func speakWithExternalProvider(text: String, provider: TTSProvider, voice: String) {
        speakingTask = Task {
            do {
                let service = try createExternalService(for: provider)
                let outputURL = FileManager.default.ttsOutputDirectory
                    .appendingPathComponent("tts_\(UUID().uuidString).mp3")
                try await service.speak(text: text, voice: voice, outputURL: outputURL)
                audioPlayer = try AVAudioPlayer(contentsOf: outputURL)
                audioPlayer?.play()
            } catch is CancellationError {
                // Stopped by user
            } catch {
                errorMessage = error.localizedDescription
            }
            isSpeaking = false
        }
    }

    private func createExternalService(for provider: TTSProvider) throws -> TTSServiceProtocol {
        switch provider {
        case .systemTTS:
            fatalError("System TTS should not use external service path")
        case .edgeTTS:
            return EdgeTTSService()
        case .fishAudio:
            guard let key = KeychainHelper.getTTSKey(for: .fishAudio), !key.isEmpty else {
                throw TTSError.providerNotConfigured("Fish Audio")
            }
            return FishAudioService(apiKey: key)
        case .miniMax:
            guard let key = KeychainHelper.getTTSKey(for: .miniMax), !key.isEmpty else {
                throw TTSError.providerNotConfigured("MiniMax")
            }
            return MiniMaxService(apiKey: key)
        }
    }

    // MARK: - Available voices for picker

    static func availableSystemVoices() -> [(id: String, name: String, lang: String)] {
        AVSpeechSynthesisVoice.speechVoices()
            .sorted { $0.language < $1.language }
            .map { voice in
                (id: voice.identifier, name: voice.name, lang: voice.language)
            }
    }
}

import AppKit

/// macOS built-in NSSpeechSynthesizer — always available, no dependencies
final class SystemTTSService: TTSServiceProtocol {

    func speak(text: String, voice: String, outputURL: URL) async throws {
        let voiceId = resolveVoice(voice)
        let synth = NSSpeechSynthesizer(voice: voiceId)

        guard let synth else {
            throw TTSError.voiceNotFound(voice)
        }

        // Speak directly through speakers (outputURL is ignored for system TTS)
        let success = synth.startSpeaking(text)
        guard success else {
            throw TTSError.synthesizeFailed("NSSpeechSynthesizer failed to start")
        }

        // Wait for completion, support cancellation
        while synth.isSpeaking {
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    /// List available system voices
    static func availableVoices() -> [(id: String, name: String, lang: String)] {
        NSSpeechSynthesizer.availableVoices.map { voiceId in
            let attrs = NSSpeechSynthesizer.attributes(forVoice: voiceId)
            let name = attrs[.name] as? String ?? voiceId.rawValue
            let lang = attrs[.localeIdentifier] as? String ?? ""
            return (id: voiceId.rawValue, name: name, lang: lang)
        }
    }

    private func resolveVoice(_ voice: String) -> NSSpeechSynthesizer.VoiceName? {
        let allVoices = NSSpeechSynthesizer.availableVoices

        // Exact match
        if let match = allVoices.first(where: { $0.rawValue == voice }) {
            return match
        }

        // Match by name (e.g., "Samantha")
        if let match = allVoices.first(where: { voiceName in
            let attrs = NSSpeechSynthesizer.attributes(forVoice: voiceName)
            let name = attrs[.name] as? String ?? ""
            return name.localizedCaseInsensitiveContains(voice)
        }) {
            return match
        }

        // Match by language prefix (e.g., "zh" or "en")
        if let match = allVoices.first(where: { voiceName in
            let attrs = NSSpeechSynthesizer.attributes(forVoice: voiceName)
            let lang = attrs[.localeIdentifier] as? String ?? ""
            return lang.hasPrefix(voice)
        }) {
            return match
        }

        // Default voice
        return NSSpeechSynthesizer.defaultVoice
    }
}

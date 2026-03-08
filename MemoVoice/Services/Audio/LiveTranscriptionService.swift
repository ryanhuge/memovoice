import Speech
import AVFoundation
import Observation

/// Live transcription using Apple's built-in SFSpeechRecognizer
@Observable
@MainActor
final class LiveTranscriptionService {
    var liveText = ""
    var isTranscribing = false
    var errorMessage: String?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    /// Request speech recognition authorization
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Start live transcription from microphone
    func startLiveTranscription(language: String? = nil) throws {
        let locale: Locale
        if let lang = language {
            locale = Locale(identifier: lang)
        } else {
            locale = Locale.current
        }

        recognizer = SFSpeechRecognizer(locale: locale)

        guard let recognizer, recognizer.isAvailable else {
            throw LiveTranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Tap callback runs on audio render thread — only use local captures,
        // never access @MainActor @Observable properties (causes dispatch crash)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // Recognition callback runs on arbitrary background queue —
        // use MainActor to update UI state safely
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let errorMsg = error?.localizedDescription
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let text {
                    self.liveText = text
                }
                if let errorMsg {
                    self.errorMessage = errorMsg
                }
            }
        }

        engine.prepare()
        try engine.start()

        isTranscribing = true
        liveText = ""
        errorMessage = nil
    }

    /// Stop live transcription
    func stopLiveTranscription() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
    }

    enum LiveTranscriptionError: LocalizedError {
        case recognizerUnavailable
        case requestFailed
        case notAuthorized

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                "Speech recognizer is not available for this language."
            case .requestFailed:
                "Failed to create speech recognition request."
            case .notAuthorized:
                "Speech recognition is not authorized. Please enable it in System Settings > Privacy."
            }
        }
    }
}

import AVFoundation
import Observation

@Observable
@MainActor
final class RecordingService {
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var monitorTask: Task<Void, Never>?
    private(set) var outputURL: URL?

    /// Start recording to a new file
    func startRecording() throws {
        let url = FileManager.default.audioDirectory
            .appendingPathComponent("recording_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        outputURL = url
        isRecording = true
        recordingDuration = 0

        // Monitor duration and level using structured concurrency
        // Runs entirely on @MainActor — no threading issues
        monitorTask = Task {
            while !Task.isCancelled {
                guard let recorder = audioRecorder, recorder.isRecording else { break }
                recordingDuration = recorder.currentTime
                recorder.updateMeters()
                let db = recorder.averagePower(forChannel: 0)
                audioLevel = max(0, (db + 60) / 60)
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    /// Stop recording and return the file URL
    func stopRecording() -> URL? {
        monitorTask?.cancel()
        monitorTask = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        return outputURL
    }

    /// Cancel and delete the recording
    func cancelRecording() {
        monitorTask?.cancel()
        monitorTask = nil
        audioRecorder?.stop()

        if let url = outputURL {
            try? FileManager.default.removeItem(at: url)
        }

        audioRecorder = nil
        outputURL = nil
        isRecording = false
        recordingDuration = 0
    }
}

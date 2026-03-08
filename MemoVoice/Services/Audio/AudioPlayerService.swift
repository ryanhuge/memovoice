import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var rate: Float = 1.0

    private var audioPlayer: AVAudioPlayer?
    private var monitorTask: Task<Void, Never>?

    func loadAudio(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.enableRate = true
        audioPlayer?.prepareToPlay()
        duration = audioPlayer?.duration ?? 0
    }

    func play() {
        audioPlayer?.rate = rate
        audioPlayer?.play()
        isPlaying = true
        startMonitor()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopMonitor()
    }

    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: Double) {
        audioPlayer?.currentTime = max(0, min(time, duration))
        currentTime = audioPlayer?.currentTime ?? 0
    }

    func skipForward(_ seconds: Double = 5) {
        seek(to: currentTime + seconds)
    }

    func skipBackward(_ seconds: Double = 5) {
        seek(to: currentTime - seconds)
    }

    func setRate(_ newRate: Float) {
        rate = newRate
        if isPlaying {
            audioPlayer?.rate = newRate
        }
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        stopMonitor()
    }

    // MARK: - Monitor (structured concurrency, stays on @MainActor)

    private func startMonitor() {
        stopMonitor()
        monitorTask = Task {
            while !Task.isCancelled {
                guard let player = audioPlayer, player.isPlaying else { break }
                currentTime = player.currentTime
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func stopMonitor() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            stopMonitor()
            currentTime = 0
        }
    }
}

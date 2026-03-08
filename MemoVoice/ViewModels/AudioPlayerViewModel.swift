import Foundation
import Observation

@Observable
@MainActor
final class AudioPlayerViewModel {
    var currentTime: Double = 0
    var duration: Double = 0
    var isPlaying = false
    var isLoaded = false
    var playbackRate: Float = 1.0
    var errorMessage: String?

    private let playerService = AudioPlayerService()

    func loadAudio(url: URL) {
        do {
            try playerService.loadAudio(url: url)
            duration = playerService.duration
            isLoaded = true
        } catch {
            errorMessage = "Failed to load audio: \(error.localizedDescription)"
        }
    }

    func togglePlayback() {
        playerService.togglePlayback()
        isPlaying = playerService.isPlaying
    }

    func seek(to time: Double) {
        playerService.seek(to: time)
        currentTime = playerService.currentTime
    }

    func skipForward(_ seconds: Double = 5) {
        playerService.skipForward(seconds)
        currentTime = playerService.currentTime
    }

    func skipBackward(_ seconds: Double = 5) {
        playerService.skipBackward(seconds)
        currentTime = playerService.currentTime
    }

    func setRate(_ rate: Float) {
        playbackRate = rate
        playerService.setRate(rate)
    }

    func updateTime() {
        currentTime = playerService.currentTime
        isPlaying = playerService.isPlaying
    }
}

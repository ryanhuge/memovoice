import Foundation
import UniformTypeIdentifiers

extension URL {
    var isYouTubeURL: Bool {
        guard let host = host() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    var isAudioFile: Bool {
        let audioExtensions = ["mp3", "wav", "m4a", "flac", "aac", "ogg", "wma", "aiff", "qta"]
        return audioExtensions.contains(pathExtension.lowercased())
    }

    var isVideoFile: Bool {
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "webm", "flv", "wmv"]
        return videoExtensions.contains(pathExtension.lowercased())
    }
}

extension UTType {
    static let srt = UTType(exportedAs: "com.memovoice.srt", conformingTo: .plainText)

    static let supportedAudioTypes: [UTType] = [.mp3, .wav, .aiff, .mpeg4Audio, .audio]
    static let supportedVideoTypes: [UTType] = [.mpeg4Movie, .quickTimeMovie, .movie, .video]
    static let supportedMediaTypes: [UTType] = supportedAudioTypes + supportedVideoTypes
}

extension FileManager {
    var appSupportDirectory: URL {
        let url = urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MemoVoice", isDirectory: true)
        try? createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    var modelsDirectory: URL {
        let url = appSupportDirectory.appendingPathComponent("Models", isDirectory: true)
        try? createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    var audioDirectory: URL {
        let url = appSupportDirectory.appendingPathComponent("Audio", isDirectory: true)
        try? createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    var templatesDirectory: URL {
        let url = appSupportDirectory.appendingPathComponent("Templates", isDirectory: true)
        try? createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    var ttsOutputDirectory: URL {
        let url = appSupportDirectory.appendingPathComponent("TTS", isDirectory: true)
        try? createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

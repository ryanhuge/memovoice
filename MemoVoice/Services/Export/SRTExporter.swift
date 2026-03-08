import Foundation

enum SRTExporter {
    /// Generate SRT content from segments
    static func export(segments: [TranscriptionSegment], includeTranslation: Bool = false) -> String {
        segments.enumerated().map { index, segment in
            let seqNum = index + 1
            let start = TimeFormatters.srtTimecode(from: segment.startTime)
            let end = TimeFormatters.srtTimecode(from: segment.endTime)

            var text = segment.text
            if includeTranslation, let translated = segment.translatedText {
                text += "\n\(translated)"
            }

            return "\(seqNum)\n\(start) --> \(end)\n\(text)\n"
        }.joined(separator: "\n")
    }

    /// Write SRT file to disk
    static func write(segments: [TranscriptionSegment], to url: URL, includeTranslation: Bool = false) throws {
        let content = export(segments: segments, includeTranslation: includeTranslation)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

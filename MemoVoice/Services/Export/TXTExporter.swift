import Foundation

enum TXTExporter {
    /// Export as plain text with optional timecodes
    static func export(
        segments: [TranscriptionSegment],
        includeTimecodes: Bool = false,
        includeTranslation: Bool = false
    ) -> String {
        segments.map { segment in
            var line = ""

            if includeTimecodes {
                line += "[\(segment.displayStartTime)] "
            }

            line += segment.text

            if includeTranslation, let translated = segment.translatedText {
                line += "\n"
                if includeTimecodes {
                    line += String(repeating: " ", count: segment.displayStartTime.count + 3)
                }
                line += translated
            }

            return line
        }.joined(separator: "\n")
    }

    /// Write plain text file
    static func write(
        segments: [TranscriptionSegment],
        to url: URL,
        includeTimecodes: Bool = false,
        includeTranslation: Bool = false
    ) throws {
        let content = export(
            segments: segments,
            includeTimecodes: includeTimecodes,
            includeTranslation: includeTranslation
        )
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

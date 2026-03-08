import Foundation

enum TimeFormatters {
    /// Convert seconds to SRT timecode: "HH:MM:SS,mmm"
    static func srtTimecode(from seconds: Double) -> String {
        let totalMs = Int(seconds * 1000)
        let hours = totalMs / 3_600_000
        let minutes = (totalMs % 3_600_000) / 60_000
        let secs = (totalMs % 60_000) / 1_000
        let ms = totalMs % 1_000
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, ms)
    }

    /// Convert seconds to display format: "12:34" or "1:02:34"
    static func displayTime(from seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Convert seconds to compact timecode for segment display: "00:12.3"
    static func segmentTimecode(from seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        let tenths = Int((seconds - Double(totalSeconds)) * 10)
        if hours > 0 {
            return String(format: "%d:%02d:%02d.%d", hours, minutes, secs, tenths)
        }
        return String(format: "%02d:%02d.%d", minutes, secs, tenths)
    }
}

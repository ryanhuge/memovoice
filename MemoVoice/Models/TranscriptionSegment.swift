import Foundation
import SwiftData

@Model
final class TranscriptionSegment {
    var id: UUID = UUID()
    var index: Int = 0
    var startTime: Double = 0
    var endTime: Double = 0
    var text: String = ""
    var translatedText: String?
    var confidence: Float?

    var project: TranscriptionProject?

    // MARK: - Computed Properties

    var startTimecode: String {
        TimeFormatters.srtTimecode(from: startTime)
    }

    var endTimecode: String {
        TimeFormatters.srtTimecode(from: endTime)
    }

    var displayStartTime: String {
        TimeFormatters.displayTime(from: startTime)
    }

    var duration: Double {
        endTime - startTime
    }

    // MARK: - Init

    init(index: Int, startTime: Double, endTime: Double, text: String, confidence: Float? = nil) {
        self.id = UUID()
        self.index = index
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.confidence = confidence
    }
}

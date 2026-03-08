import Foundation
import SwiftData

@Model
final class TranscriptionProject {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sourceTypeRaw: String = SourceType.audioFile.rawValue
    var sourceURLString: String?
    var audioFileBookmark: Data?
    var language: String?
    var modelName: String = "large-v3_turbo"
    var statusRaw: String = ProjectStatus.importing.rawValue
    var progress: Double = 0
    var errorMessage: String?
    var audioDuration: Double = 0

    @Relationship(deleteRule: .cascade, inverse: \TranscriptionSegment.project)
    var segments: [TranscriptionSegment]? = []

    var translatedLanguage: String?
    var meetingSummary: String?
    var meetingTemplateName: String?

    // MARK: - Computed Properties

    var sourceType: SourceType {
        get { SourceType(rawValue: sourceTypeRaw) ?? .audioFile }
        set { sourceTypeRaw = newValue.rawValue }
    }

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .importing }
        set { statusRaw = newValue.rawValue }
    }

    var sourceURL: URL? {
        get { sourceURLString.flatMap { URL(string: $0) } }
        set { sourceURLString = newValue?.absoluteString }
    }

    var sortedSegments: [TranscriptionSegment] {
        (segments ?? []).sorted { $0.index < $1.index }
    }

    var displayDuration: String {
        TimeFormatters.displayTime(from: audioDuration)
    }

    // MARK: - Enums

    enum SourceType: String, Codable, CaseIterable {
        case audioFile
        case videoFile
        case youtubeURL

        var displayName: String {
            switch self {
            case .audioFile: String(localized: "Audio")
            case .videoFile: String(localized: "Video")
            case .youtubeURL: String(localized: "YouTube")
            }
        }

        var icon: String {
            switch self {
            case .audioFile: "waveform"
            case .videoFile: "film"
            case .youtubeURL: "play.rectangle"
            }
        }
    }

    enum ProjectStatus: String, Codable, CaseIterable {
        case importing
        case extractingAudio
        case transcribing
        case completed
        case failed

        var displayName: String {
            switch self {
            case .importing: String(localized: "Importing...")
            case .extractingAudio: String(localized: "Extracting Audio...")
            case .transcribing: String(localized: "Transcribing...")
            case .completed: String(localized: "Completed")
            case .failed: String(localized: "Failed")
            }
        }

        var isProcessing: Bool {
            switch self {
            case .importing, .extractingAudio, .transcribing: true
            case .completed, .failed: false
            }
        }
    }

    // MARK: - Init

    init(title: String, sourceType: SourceType, sourceURL: URL? = nil, modelName: String = "large-v3_turbo") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sourceTypeRaw = sourceType.rawValue
        self.sourceURLString = sourceURL?.absoluteString
        self.modelName = modelName
    }
}

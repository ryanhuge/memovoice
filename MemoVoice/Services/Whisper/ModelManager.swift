import Foundation
import WhisperKit

@Observable
@MainActor
final class ModelManager {
    var availableModels: [ModelInfo] = []
    var downloadingModel: String?
    var downloadProgress: Double = 0

    struct ModelInfo: Identifiable {
        let id: String
        let name: String
        let displayName: String
        let size: String
        var isDownloaded: Bool

        static let predefined: [ModelInfo] = [
            ModelInfo(id: "tiny", name: "tiny", displayName: "Tiny", size: "~75 MB", isDownloaded: false),
            ModelInfo(id: "base", name: "base", displayName: "Base", size: "~140 MB", isDownloaded: false),
            ModelInfo(id: "small", name: "small", displayName: "Small", size: "~466 MB", isDownloaded: false),
            ModelInfo(id: "medium", name: "medium", displayName: "Medium", size: "~1.5 GB", isDownloaded: false),
            ModelInfo(id: "large-v3", name: "large-v3", displayName: "Large V3", size: "~2.9 GB", isDownloaded: false),
            ModelInfo(id: "large-v3_turbo", name: "large-v3_turbo", displayName: "Large V3 Turbo", size: "~1.6 GB", isDownloaded: false),
        ]
    }

    func refreshModels() async {
        let whisperService = WhisperService.shared
        self.availableModels = ModelInfo.predefined.map { info in
            var updated = info
            updated.isDownloaded = whisperService.isModelDownloaded(info.name)
            return updated
        }
    }
}

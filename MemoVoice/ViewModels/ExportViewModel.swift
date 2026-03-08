import Foundation
import AppKit

@Observable
@MainActor
final class ExportViewModel {
    var isExporting = false
    var errorMessage: String?

    func export(
        project: TranscriptionProject,
        format: ExportFormat,
        includeTimecodes: Bool = true,
        includeTranslation: Bool = false
    ) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(project.title).\(format.fileExtension)"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        isExporting = true
        errorMessage = nil

        let segments = project.sortedSegments

        do {
            switch format {
            case .srt:
                try SRTExporter.write(
                    segments: segments,
                    to: url,
                    includeTranslation: includeTranslation
                )

            case .txt:
                try TXTExporter.write(
                    segments: segments,
                    to: url,
                    includeTimecodes: includeTimecodes,
                    includeTranslation: includeTranslation
                )

            case .markdown:
                try MarkdownExporter.write(
                    title: project.title,
                    segments: segments,
                    to: url,
                    includeTimecodes: includeTimecodes,
                    includeTranslation: includeTranslation,
                    meetingSummary: project.meetingSummary
                )

            case .docx:
                try DOCXExporter.write(
                    title: project.title,
                    segments: segments,
                    to: url,
                    includeTimecodes: includeTimecodes,
                    includeTranslation: includeTranslation
                )
            }

            // Open the file in Finder
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")

        } catch {
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }
}

import Foundation
import SwiftData
import Observation
import os

private let logger = Logger(subsystem: "com.memovoice", category: "Summary")

@Observable
@MainActor
final class SummaryViewModel {
    var isGenerating = false
    var summary = ""
    var statusMessage = ""
    var errorMessage: String?

    private let summaryService = AISummaryService()

    func generateSummary(
        project: TranscriptionProject,
        template: MeetingTemplate,
        modelContext: ModelContext
    ) async {
        isGenerating = true
        errorMessage = nil
        statusMessage = String(localized: "Preparing transcript…")

        logger.info("Starting summary generation with template: \(template.name)")

        let transcript = project.sortedSegments
            .map { "[\(TimeFormatters.displayTime(from: $0.startTime))] \($0.text)" }
            .joined(separator: "\n")

        guard !transcript.isEmpty else {
            logger.warning("No transcript segments found")
            errorMessage = String(localized: "No transcript segments to summarize.")
            isGenerating = false
            return
        }

        logger.info("Transcript length: \(transcript.count) chars, segments: \(project.sortedSegments.count)")
        statusMessage = String(localized: "Sending to Claude CLI…")

        do {
            let result = try await summaryService.generateSummary(
                transcript: transcript,
                template: template
            ) { @Sendable status in
                logger.debug("Progress: \(status)")
            }

            logger.info("Summary generated successfully: \(result.prefix(100))...")
            summary = result
            project.meetingSummary = result
            project.meetingTemplateName = template.name
            project.updatedAt = Date()
            try? modelContext.save()
        } catch {
            logger.error("Summary generation failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        statusMessage = ""
        isGenerating = false
    }
}

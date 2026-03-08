import Foundation
import os

private let logger = Logger(subsystem: "com.memovoice", category: "AISummary")

final class AISummaryService: Sendable {
    private let claudePath: String

    init(claudePath: String = "/opt/homebrew/bin/claude") {
        self.claudePath = claudePath
    }

    /// Generate a meeting summary using Claude CLI
    func generateSummary(
        transcript: String,
        template: MeetingTemplate,
        progressCallback: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let prompt = """
        \(template.systemPrompt)

        Expected sections: \(template.sections.joined(separator: ", "))

        Transcript:
        \(transcript)
        """

        logger.info("claudePath: \(self.claudePath)")
        logger.info("Template: \(template.name), sections: \(template.sections.joined(separator: ", "))")
        logger.info("Prompt length: \(prompt.count) chars")

        progressCallback("Sending to Claude CLI...")

        guard let promptData = prompt.data(using: .utf8) else {
            logger.error("Failed to encode prompt to UTF-8")
            throw SummaryError.generationFailed("Failed to encode prompt")
        }

        logger.info("Calling ProcessRunner.run...")
        let result = try await ProcessRunner.run(
            executablePath: claudePath,
            arguments: ["-p"],
            stdinData: promptData,
            timeout: 300
        )

        logger.info("Process exit code: \(result.exitCode)")
        if !result.stderr.isEmpty {
            logger.warning("stderr: \(result.stderr)")
        }

        guard result.isSuccess else {
            logger.error("Process failed: \(result.stderr)")
            throw SummaryError.generationFailed(result.stderr)
        }

        let summary = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else {
            logger.error("Empty response from Claude CLI")
            throw SummaryError.emptyResponse
        }

        logger.info("Summary generated: \(summary.prefix(200))...")
        return summary
    }

    enum SummaryError: LocalizedError {
        case generationFailed(String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .generationFailed(let msg):
                "Summary generation failed: \(msg)"
            case .emptyResponse:
                "The AI returned an empty response."
            }
        }
    }
}

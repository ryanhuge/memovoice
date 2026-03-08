import Foundation
import os

private let logger = Logger(subsystem: "com.memovoice", category: "ClaudeCLI")

final class ClaudeCLIService: TranslationServiceProtocol {
    private let claudePath: String

    init(claudePath: String = "/opt/homebrew/bin/claude") {
        self.claudePath = claudePath
    }

    func translate(
        text: String,
        from sourceLanguage: String?,
        to targetLanguage: String
    ) async throws -> String {
        let sourceLangStr = sourceLanguage.map { "from \($0) " } ?? ""
        let prompt = "Translate the following text \(sourceLangStr)to \(targetLanguage). Output ONLY the translation, no explanations or additional text.\n\n\(text)"

        guard let promptData = prompt.data(using: .utf8) else {
            throw TranslationError.invalidResponse
        }

        logger.info("Translating to \(targetLanguage), text length: \(text.count)")
        let result = try await ProcessRunner.run(
            executablePath: claudePath,
            arguments: ["-p"],
            stdinData: promptData,
            timeout: 120
        )

        logger.info("Exit code: \(result.exitCode)")
        if !result.stderr.isEmpty {
            logger.warning("stderr: \(result.stderr)")
        }

        guard result.isSuccess else {
            logger.error("Translation CLI failed: \(result.stderr)")
            throw TranslationError.cliError(result.stderr)
        }

        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else {
            logger.error("Empty translation response")
            throw TranslationError.invalidResponse
        }

        return output
    }

    /// Translate segments in batches
    func translateSegments(
        _ segments: [TranscriptionSegment],
        from sourceLanguage: String?,
        to targetLanguage: String,
        batchSize: Int = 10,
        progressCallback: @escaping (Double) -> Void
    ) async throws -> [(Int, String)] {
        var results: [(Int, String)] = []
        let total = segments.count

        for batchStart in stride(from: 0, to: total, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, total)
            let batch = Array(segments[batchStart..<batchEnd])

            let numberedText = batch.enumerated().map { i, seg in
                "[\(batchStart + i + 1)] \(seg.text)"
            }.joined(separator: "\n")

            let sourceLangStr = sourceLanguage.map { "from \($0) " } ?? ""
            let prompt = """
            Translate the following numbered segments \(sourceLangStr)to \(targetLanguage). \
            Keep the numbering format [N] exactly as is. Output ONLY the translations, one per line with the same numbering.

            \(numberedText)
            """

            guard let promptData = prompt.data(using: .utf8) else {
                continue
            }

            let result = try await ProcessRunner.run(
                executablePath: claudePath,
                arguments: ["-p"],
                stdinData: promptData,
                timeout: 180
            )

            guard result.isSuccess else {
                throw TranslationError.cliError(result.stderr)
            }

            let lines = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }

            for line in lines {
                if let range = line.range(of: #"^\[(\d+)\]\s*"#, options: .regularExpression) {
                    let numberStr = line[range].filter { $0.isNumber }
                    if let number = Int(numberStr) {
                        let translation = String(line[range.upperBound...])
                        results.append((number - 1, translation))
                    }
                }
            }

            progressCallback(Double(batchEnd) / Double(total))
        }

        return results
    }
}

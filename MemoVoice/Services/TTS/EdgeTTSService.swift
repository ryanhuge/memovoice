import Foundation

/// Edge TTS service using the edge-tts CLI tool
final class EdgeTTSService: TTSServiceProtocol {

    func speak(text: String, voice: String, outputURL: URL) async throws {
        guard let edgeTTSPath = findEdgeTTS() else {
            throw TTSError.synthesizeFailed(
                "edge-tts is not installed. Install with: pip3 install edge-tts"
            )
        }

        let result = try await ProcessRunner.run(
            executablePath: edgeTTSPath,
            arguments: [
                "--voice", voice,
                "--text", text,
                "--write-media", outputURL.path
            ],
            timeout: 120
        )

        guard result.isSuccess else {
            throw TTSError.synthesizeFailed(result.stderr)
        }
    }

    static var isAvailable: Bool {
        findExecutable() != nil
    }

    private func findEdgeTTS() -> String? {
        Self.findExecutable()
    }

    private static func findExecutable() -> String? {
        let paths = [
            "/opt/homebrew/bin/edge-tts",
            "/usr/local/bin/edge-tts",
            "\(NSHomeDirectory())/.local/bin/edge-tts",
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}

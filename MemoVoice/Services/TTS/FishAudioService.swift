import Foundation

final class FishAudioService: TTSServiceProtocol {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func speak(text: String, voice: String, outputURL: URL) async throws {
        let url = URL(string: "https://api.fish.audio/v1/tts")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "text": text,
            "reference_id": voice,
            "format": "mp3"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TTSError.synthesizeFailed("Fish Audio API error: \(errorText)")
        }

        try data.write(to: outputURL)
    }
}

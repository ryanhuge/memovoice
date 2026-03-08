import Foundation

final class MiniMaxService: TTSServiceProtocol {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func speak(text: String, voice: String, outputURL: URL) async throws {
        let url = URL(string: "https://api.minimaxi.chat/v1/t2a_v2")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "speech-02-hd",
            "text": text,
            "voice_setting": [
                "voice_id": voice
            ],
            "audio_setting": [
                "format": "mp3",
                "sample_rate": 32000
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TTSError.synthesizeFailed("MiniMax API error: \(errorText)")
        }

        // Parse JSON response to extract audio data
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let audioData = json["data"] as? [String: Any],
              let audioBase64 = audioData["audio"] as? String,
              let audioBytes = Data(base64Encoded: audioBase64) else {
            // If response is raw audio data instead of JSON
            if data.count > 1000 {
                try data.write(to: outputURL)
                return
            }
            throw TTSError.synthesizeFailed("Invalid response from MiniMax")
        }

        try audioBytes.write(to: outputURL)
    }
}

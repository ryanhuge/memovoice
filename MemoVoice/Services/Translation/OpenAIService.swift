import Foundation

final class OpenAIService: TranslationServiceProtocol {
    private let apiKey: String
    private let baseURL: URL
    private let model: String

    init(apiKey: String, baseURL: URL = URL(string: "https://api.openai.com/v1/chat/completions")!, model: String = "gpt-4o") {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
    }

    func translate(text: String, from sourceLanguage: String?, to targetLanguage: String) async throws -> String {
        let sourceLangStr = sourceLanguage.map { "from \($0) " } ?? ""
        let systemPrompt = "You are a translator. Translate \(sourceLangStr)to \(targetLanguage). Output only the translation, nothing else."

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranslationError.apiError(errorText)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw TranslationError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

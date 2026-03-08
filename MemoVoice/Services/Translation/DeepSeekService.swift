import Foundation

final class DeepSeekService: TranslationServiceProtocol {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func translate(text: String, from sourceLanguage: String?, to targetLanguage: String) async throws -> String {
        // DeepSeek uses OpenAI-compatible API format
        let service = OpenAIService(
            apiKey: apiKey,
            baseURL: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
            model: "deepseek-chat"
        )
        return try await service.translate(text: text, from: sourceLanguage, to: targetLanguage)
    }
}

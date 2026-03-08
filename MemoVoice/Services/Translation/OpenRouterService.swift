import Foundation

final class OpenRouterService: TranslationServiceProtocol {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func translate(text: String, from sourceLanguage: String?, to targetLanguage: String) async throws -> String {
        // OpenRouter uses OpenAI-compatible API format
        let service = OpenAIService(
            apiKey: apiKey,
            baseURL: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
            model: "anthropic/claude-sonnet-4"
        )
        return try await service.translate(text: text, from: sourceLanguage, to: targetLanguage)
    }
}

import Foundation

protocol TranslationServiceProtocol: Sendable {
    func translate(
        text: String,
        from sourceLanguage: String?,
        to targetLanguage: String
    ) async throws -> String
}

enum TranslationError: LocalizedError {
    case providerNotConfigured(String)
    case apiError(String)
    case cliError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .providerNotConfigured(let provider):
            "\(provider) is not configured. Please set your API key in Settings."
        case .apiError(let msg):
            "Translation API error: \(msg)"
        case .cliError(let msg):
            "CLI error: \(msg)"
        case .invalidResponse:
            "Invalid response from translation service."
        }
    }
}

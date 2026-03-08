import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class TranslationViewModel {
    var isTranslating = false
    var translationProgress: Double = 0
    var errorMessage: String?

    /// Translate all segments of a project
    func translateAll(
        project: TranscriptionProject,
        targetLanguage: String,
        provider: TranslationProvider,
        modelContext: ModelContext
    ) async {
        isTranslating = true
        translationProgress = 0
        errorMessage = nil

        do {
            let service = try createService(for: provider)
            let segments = project.sortedSegments

            guard !segments.isEmpty else {
                errorMessage = String(localized: "No segments to translate.")
                isTranslating = false
                return
            }

            for (index, segment) in segments.enumerated() {
                let translated = try await service.translate(
                    text: segment.text,
                    from: project.language,
                    to: targetLanguage
                )

                segment.translatedText = translated
                translationProgress = Double(index + 1) / Double(segments.count)
            }

            project.translatedLanguage = targetLanguage
            project.updatedAt = Date()
            try? modelContext.save()

        } catch {
            errorMessage = error.localizedDescription
        }

        isTranslating = false
    }

    private func createService(for provider: TranslationProvider) throws -> TranslationServiceProtocol {
        switch provider {
        case .claudeCLI:
            return ClaudeCLIService()
        case .openAI:
            guard let key = KeychainHelper.getAPIKey(for: .openAI), !key.isEmpty else {
                throw TranslationError.providerNotConfigured("OpenAI")
            }
            return OpenAIService(apiKey: key)
        case .gemini:
            guard let key = KeychainHelper.getAPIKey(for: .gemini), !key.isEmpty else {
                throw TranslationError.providerNotConfigured("Gemini")
            }
            return GeminiService(apiKey: key)
        case .deepSeek:
            guard let key = KeychainHelper.getAPIKey(for: .deepSeek), !key.isEmpty else {
                throw TranslationError.providerNotConfigured("DeepSeek")
            }
            return DeepSeekService(apiKey: key)
        case .openRouter:
            guard let key = KeychainHelper.getAPIKey(for: .openRouter), !key.isEmpty else {
                throw TranslationError.providerNotConfigured("OpenRouter")
            }
            return OpenRouterService(apiKey: key)
        }
    }
}

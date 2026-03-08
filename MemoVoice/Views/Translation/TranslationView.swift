import SwiftUI
import SwiftData

struct TranslationControlBar: View {
    @Bindable var project: TranscriptionProject
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TranslationViewModel()
    @State private var targetLanguage: SupportedLanguage = .zhTW
    @State private var selectedProvider: TranslationProvider = .claudeCLI
    @State private var showExportSheet = false

    private var hasTranslation: Bool {
        project.sortedSegments.contains { $0.translatedText != nil }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                Picker("Translate to", selection: $targetLanguage) {
                    ForEach(SupportedLanguage.allCases.filter { $0 != .auto }) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .frame(width: 180)

                Picker("Provider", selection: $selectedProvider) {
                    ForEach(TranslationProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .frame(width: 160)

                Spacer()

                if viewModel.isTranslating {
                    ProgressView(value: viewModel.translationProgress)
                        .frame(width: 100)
                    Text("\(Int(viewModel.translationProgress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                }

                if hasTranslation {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    Task {
                        await viewModel.translateAll(
                            project: project,
                            targetLanguage: targetLanguage.rawValue,
                            provider: selectedProvider,
                            modelContext: modelContext
                        )
                    }
                } label: {
                    Label(
                        viewModel.isTranslating ? "Translating…" : "Translate All",
                        systemImage: viewModel.isTranslating ? "hourglass" : "character.book.closed"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isTranslating || project.sortedSegments.isEmpty)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let translatedLang = project.translatedLanguage {
                Text("Translated to: \(translatedLang)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(project: project)
        }
    }
}

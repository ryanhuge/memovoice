import SwiftUI
import AVFoundation

struct TTSControlView: View {
    let project: TranscriptionProject
    @State private var viewModel = TTSViewModel()
    @State private var selectedProvider: TTSProvider = .systemTTS
    @State private var selectedVoice = ""
    @State private var textSource: TextSource = .original

    enum TextSource: String, CaseIterable {
        case original = "Original"
        case translated = "Translated"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Picker("TTS", selection: $selectedProvider) {
                    ForEach(TTSProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .frame(width: 160)
                .onChange(of: selectedProvider) { _, newValue in
                    updateDefaultVoice(for: newValue)
                }

                Picker("Voice", selection: $selectedVoice) {
                    if selectedProvider == .systemTTS {
                        ForEach(TTSViewModel.availableSystemVoices(), id: \.id) { voice in
                            Text("\(voice.name) (\(voice.lang))").tag(voice.id)
                        }
                    } else {
                        Text(selectedVoice).tag(selectedVoice)
                    }
                }
                .frame(width: 220)

                Picker("Source", selection: $textSource) {
                    Text("Original").tag(TextSource.original)
                    if hasTranslation {
                        Text("Translated").tag(TextSource.translated)
                    }
                }
                .frame(width: 150)

                Spacer()

                Button {
                    if viewModel.isSpeaking {
                        viewModel.stop()
                    } else {
                        startSpeaking()
                    }
                } label: {
                    Label(viewModel.isSpeaking ? "Stop" : "Speak",
                          systemImage: viewModel.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
        .onAppear {
            updateDefaultVoice(for: selectedProvider)
        }
    }

    private var hasTranslation: Bool {
        project.sortedSegments.contains { $0.translatedText != nil }
    }

    private func startSpeaking() {
        let segments = project.sortedSegments
        let text: String
        switch textSource {
        case .original:
            text = segments.map(\.text).joined(separator: " ")
        case .translated:
            text = segments.compactMap(\.translatedText).joined(separator: " ")
        }

        guard !text.isEmpty else {
            viewModel.errorMessage = String(localized: "No text to speak.")
            return
        }

        viewModel.speak(
            text: text,
            provider: selectedProvider,
            voice: selectedVoice
        )
    }

    private func updateDefaultVoice(for provider: TTSProvider) {
        switch provider {
        case .systemTTS:
            let lang = project.language ?? "en"
            let voices = TTSViewModel.availableSystemVoices()
            if let match = voices.first(where: { $0.lang.hasPrefix(lang) }) {
                selectedVoice = match.id
            } else if let first = voices.first {
                selectedVoice = first.id
            }
        case .edgeTTS:
            selectedVoice = "en-US-JennyNeural"
        case .fishAudio, .miniMax:
            selectedVoice = "default"
        }
    }
}

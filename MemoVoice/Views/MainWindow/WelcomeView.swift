import SwiftUI

struct WelcomeView: View {
    let onImport: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("MemoVoice")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Local speech-to-text transcription\npowered by Whisper AI")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                FeatureRow(icon: "waveform", text: "Transcribe audio & video files")
                FeatureRow(icon: "globe", text: "Multi-language recognition")
                FeatureRow(icon: "character.book.closed", text: "One-click translation")
                FeatureRow(icon: "play.rectangle", text: "YouTube URL support")
                FeatureRow(icon: "doc.text", text: "Export to SRT, DOCX, TXT, Markdown")
                FeatureRow(icon: "speaker.wave.3", text: "Text-to-speech playback")
                FeatureRow(icon: "list.clipboard", text: "AI meeting summaries")
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: onImport) {
                Label("Import File", systemImage: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("n", modifiers: .command)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

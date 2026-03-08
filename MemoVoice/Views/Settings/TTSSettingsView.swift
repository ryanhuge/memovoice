import SwiftUI

struct TTSSettingsView: View {
    @AppStorage("ttsProvider") private var ttsProvider = "edge-tts"
    @AppStorage("defaultVoice") private var defaultVoice = "en-US-JennyNeural"

    var body: some View {
        Form {
            Section("Default TTS Provider") {
                Picker("Provider", selection: $ttsProvider) {
                    ForEach(TTSProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider.rawValue)
                    }
                }

                TextField("Default Voice", text: $defaultVoice)

                Text("Edge TTS is free and requires no API key. Fish Audio and MiniMax require API keys configured in the API Keys tab.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Edge TTS Voices") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Common voices:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(commonVoices, id: \.0) { voice, desc in
                        HStack {
                            Text(voice)
                                .font(.system(.caption, design: .monospaced))
                            Text("- \(desc)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Use") {
                                defaultVoice = voice
                            }
                            .controlSize(.mini)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var commonVoices: [(String, String)] {
        [
            ("en-US-JennyNeural", String(localized: "English Female")),
            ("en-US-GuyNeural", String(localized: "English Male")),
            ("zh-TW-HsiaoChenNeural", String(localized: "Chinese (TW) Female")),
            ("zh-TW-YunJheNeural", String(localized: "Chinese (TW) Male")),
            ("zh-CN-XiaoxiaoNeural", String(localized: "Chinese (CN) Female")),
            ("ja-JP-NanamiNeural", String(localized: "Japanese Female")),
            ("ko-KR-SunHiNeural", String(localized: "Korean Female")),
            ("fr-FR-DeniseNeural", String(localized: "French Female")),
            ("de-DE-KatjaNeural", String(localized: "German Female")),
            ("es-ES-ElviraNeural", String(localized: "Spanish Female")),
        ]
    }
}

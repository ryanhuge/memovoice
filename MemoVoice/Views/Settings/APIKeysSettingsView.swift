import SwiftUI

struct APIKeysSettingsView: View {
    @State private var openAIKey = ""
    @State private var geminiKey = ""
    @State private var deepSeekKey = ""
    @State private var openRouterKey = ""
    @State private var fishAudioKey = ""
    @State private var miniMaxKey = ""
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section("Translation API Keys") {
                APIKeyRow(
                    provider: "OpenAI",
                    key: $openAIKey,
                    keychainKey: TranslationProvider.openAI.keychainKey
                )
                APIKeyRow(
                    provider: "Google Gemini",
                    key: $geminiKey,
                    keychainKey: TranslationProvider.gemini.keychainKey
                )
                APIKeyRow(
                    provider: "DeepSeek",
                    key: $deepSeekKey,
                    keychainKey: TranslationProvider.deepSeek.keychainKey
                )
                APIKeyRow(
                    provider: "OpenRouter",
                    key: $openRouterKey,
                    keychainKey: TranslationProvider.openRouter.keychainKey
                )
            }

            Section("TTS API Keys") {
                APIKeyRow(
                    provider: "Fish Audio",
                    key: $fishAudioKey,
                    keychainKey: TTSProvider.fishAudio.keychainKey
                )
                APIKeyRow(
                    provider: "MiniMax",
                    key: $miniMaxKey,
                    keychainKey: TTSProvider.miniMax.keychainKey
                )
            }

            Section {
                HStack {
                    Text("Claude CLI")
                        .fontWeight(.medium)
                    Spacer()
                    Label("Uses system Claude CLI", systemImage: "terminal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Claude")
            } footer: {
                Text("Claude CLI uses your existing authentication. No API key needed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { loadKeys() }
    }

    private func loadKeys() {
        openAIKey = KeychainHelper.getAPIKey(for: .openAI) ?? ""
        geminiKey = KeychainHelper.getAPIKey(for: .gemini) ?? ""
        deepSeekKey = KeychainHelper.getAPIKey(for: .deepSeek) ?? ""
        openRouterKey = KeychainHelper.getAPIKey(for: .openRouter) ?? ""
        fishAudioKey = KeychainHelper.getTTSKey(for: .fishAudio) ?? ""
        miniMaxKey = KeychainHelper.getTTSKey(for: .miniMax) ?? ""
    }
}

struct APIKeyRow: View {
    let provider: String
    @Binding var key: String
    let keychainKey: String

    @State private var isEditing = false
    @State private var saved = false

    var body: some View {
        HStack {
            Text(provider)
                .frame(width: 120, alignment: .leading)

            if isEditing {
                SecureField("API Key", text: $key)
                    .textFieldStyle(.roundedBorder)

                Button("Save") {
                    try? KeychainHelper.save(key: keychainKey, value: key)
                    isEditing = false
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Cancel") {
                    key = KeychainHelper.get(key: keychainKey) ?? ""
                    isEditing = false
                }
                .controlSize(.small)
            } else {
                if key.isEmpty {
                    Text("Not set")
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(repeating: "•", count: 20))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if saved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Button {
                    isEditing = true
                } label: {
                    if key.isEmpty {
                        Text("Set")
                    } else {
                        Text("Edit")
                    }
                }
                .controlSize(.small)
            }
        }
    }
}

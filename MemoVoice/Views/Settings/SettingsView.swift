import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            APIKeysSettingsView()
                .tabItem { Label("API Keys", systemImage: "key") }

            ToolsSettingsView()
                .tabItem { Label("Tools", systemImage: "wrench") }

            TemplateEditorView()
                .tabItem { Label("Templates", systemImage: "doc.text") }

            TTSSettingsView()
                .tabItem { Label("TTS", systemImage: "speaker.wave.3") }
        }
        .frame(width: 600, height: 450)
    }
}

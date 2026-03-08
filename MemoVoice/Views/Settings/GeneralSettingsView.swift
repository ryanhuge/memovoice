import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "large-v3_turbo"
    @AppStorage("chunkDuration") private var chunkDuration: Double = 30.0
    @AppStorage("overlapDuration") private var overlapDuration: Double = 2.0
    @AppStorage("targetLanguage") private var targetLanguage = "zh-TW"

    var body: some View {
        Form {
            Section("Whisper Model") {
                Picker("Default Model", selection: $selectedModel) {
                    Text("Tiny (~75MB, fastest)").tag("tiny")
                    Text("Base (~140MB)").tag("base")
                    Text("Small (~466MB)").tag("small")
                    Text("Medium (~1.5GB)").tag("medium")
                    Text("Large V3 (~2.9GB, most accurate)").tag("large-v3")
                    Text("Large V3 Turbo (~1.6GB, recommended)").tag("large-v3_turbo")
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Chunk Duration:")
                        Text("\(Int(chunkDuration))s")
                            .monospacedDigit()
                    }
                    Slider(value: $chunkDuration, in: 15...60, step: 5)
                    Text("Duration of each audio chunk for processing. Smaller = less memory, more overhead.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Overlap:")
                        Text("\(Int(overlapDuration))s")
                            .monospacedDigit()
                    }
                    Slider(value: $overlapDuration, in: 0...5, step: 0.5)
                    Text("Overlap between chunks to prevent word splitting at boundaries.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Translation") {
                Picker("Default Target Language", selection: $targetLanguage) {
                    ForEach(SupportedLanguage.allCases.filter { $0 != .auto }) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

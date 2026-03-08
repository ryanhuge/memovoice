import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "large-v3_turbo"
    @AppStorage("targetLanguage") private var targetLanguage = "zh-TW"
    @State private var modelManager = ModelManager()
    @State private var confirmDelete: String?

    var body: some View {
        Form {
            Section("Default Model") {
                Picker("Default Model", selection: $selectedModel) {
                    ForEach(ModelManager.ModelInfo.predefined) { model in
                        Text("\(model.displayName) (\(model.size))").tag(model.name)
                    }
                }
            }

            Section("Model Management") {
                ForEach(modelManager.availableModels) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(model.displayName)
                                    .fontWeight(model.name == selectedModel ? .semibold : .regular)
                                if model.name == selectedModel {
                                    Text("Default")
                                        .font(.caption2)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(.blue.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            Text(model.size)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if modelManager.downloadingModel == model.name {
                            ProgressView(value: modelManager.downloadProgress)
                                .frame(width: 80)
                            Text("\(Int(modelManager.downloadProgress * 100))%")
                                .font(.caption)
                                .monospacedDigit()
                                .frame(width: 36)
                        } else if model.isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Button {
                                confirmDelete = model.name
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("Delete model")
                        } else {
                            Button("Download") {
                                Task {
                                    await modelManager.downloadModel(model.name)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
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
        .onAppear { modelManager.refreshModels() }
        .alert("Delete Model?", isPresented: Binding(
            get: { confirmDelete != nil },
            set: { if !$0 { confirmDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { confirmDelete = nil }
            Button("Delete", role: .destructive) {
                if let name = confirmDelete {
                    modelManager.deleteModel(name)
                }
                confirmDelete = nil
            }
        } message: {
            Text("This model will need to be re-downloaded before use.")
        }
    }
}

import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (TranscriptionProject) -> Void

    @State private var selectedTab = 0
    @State private var selectedFileURL: URL?
    @State private var youtubeURL = ""
    @State private var projectTitle = ""
    @State private var selectedLanguage: SupportedLanguage = .zhTW
    @State private var selectedModel = AppState.shared.selectedModel
    @State private var isDragOver = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Transcription")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Tab selector
            Picker("Input Source", selection: $selectedTab) {
                Label("Audio/Video File", systemImage: "doc.badge.plus").tag(0)
                Label("YouTube URL", systemImage: "play.rectangle").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            // Tab content
            Group {
                if selectedTab == 0 {
                    fileInputView
                } else {
                    youtubeInputView
                }
            }
            .frame(minHeight: 200)

            Divider()

            // Options
            Form {
                TextField("Project Title", text: $projectTitle)

                Picker("Language", selection: $selectedLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }

                Picker("Model", selection: $selectedModel) {
                    Text("Tiny (~75MB)").tag("tiny")
                    Text("Base (~140MB)").tag("base")
                    Text("Small (~466MB)").tag("small")
                    Text("Medium (~1.5GB)").tag("medium")
                    Text("Large V3 (~2.9GB)").tag("large-v3")
                    Text("Large V3 Turbo (~1.6GB)").tag("large-v3_turbo")
                }
            }
            .formStyle(.grouped)
            .frame(height: 180)

            // Error
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Divider()

            // Actions
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Start Transcription") {
                    startTranscription()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canStart)
            }
            .padding()
        }
        .frame(width: 550, height: 620)
    }

    // MARK: - File Input

    private var fileInputView: some View {
        VStack(spacing: 16) {
            if let url = selectedFileURL {
                HStack {
                    Image(systemName: url.isVideoFile ? "film" : "waveform")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent)
                            .font(.headline)
                        Text(url.deletingLastPathComponent().path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Change") { openFilePicker() }
                }
                .padding()
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Drag & drop or click to select")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Supports: MP3, WAV, M4A, FLAC, MP4, MOV, MKV")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                                     style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                )
                .onTapGesture { openFilePicker() }
                .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers)
                }
            }
        }
        .padding()
    }

    // MARK: - YouTube Input

    private var youtubeInputView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            TextField("Paste YouTube URL here...", text: $youtubeURL)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            if !youtubeURL.isEmpty {
                if URL(string: youtubeURL)?.isYouTubeURL == true {
                    Label("Valid YouTube URL", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                } else {
                    Label("Invalid YouTube URL", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Logic

    private var canStart: Bool {
        if selectedTab == 0 {
            return selectedFileURL != nil
        } else {
            return URL(string: youtubeURL)?.isYouTubeURL == true
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = UTType.supportedMediaTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            selectedFileURL = url
            if projectTitle.isEmpty {
                projectTitle = url.deletingPathExtension().lastPathComponent
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    selectedFileURL = url
                    if projectTitle.isEmpty {
                        projectTitle = url.deletingPathExtension().lastPathComponent
                    }
                }
            }
        }
        return true
    }

    private func startTranscription() {
        let title = projectTitle.isEmpty ? "Untitled" : projectTitle

        if selectedTab == 0, let fileURL = selectedFileURL {
            let sourceType: TranscriptionProject.SourceType = fileURL.isVideoFile ? .videoFile : .audioFile
            let project = TranscriptionProject(
                title: title,
                sourceType: sourceType,
                sourceURL: fileURL,
                modelName: selectedModel
            )
            project.language = selectedLanguage.whisperCode
            onCreate(project)
            dismiss()
        } else if selectedTab == 1, let url = URL(string: youtubeURL), url.isYouTubeURL {
            let project = TranscriptionProject(
                title: title,
                sourceType: .youtubeURL,
                sourceURL: url,
                modelName: selectedModel
            )
            project.language = selectedLanguage.whisperCode
            onCreate(project)
            dismiss()
        }
    }
}

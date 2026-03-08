import SwiftUI
import AVFoundation

struct RecordingView: View {
    let onCreate: (TranscriptionProject) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var recorder = RecordingService()
    @State private var projectTitle = ""
    @State private var selectedLanguage: SupportedLanguage = .zhTW
    @State private var selectedModel = AppState.shared.selectedModel
    @State private var micPermission: AVAuthorizationStatus = .notDetermined
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Record Audio")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") {
                    recorder.cancelRecording()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            VStack(spacing: 20) {
                // Waveform / Level indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.quaternary.opacity(0.3))

                    if recorder.isRecording {
                        // Animated level bars
                        HStack(spacing: 3) {
                            ForEach(0..<20, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(barColor(for: i))
                                    .frame(width: 8, height: barHeight(for: i))
                                    .animation(
                                        .easeInOut(duration: 0.1),
                                        value: recorder.audioLevel
                                    )
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "mic.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Press the button to start recording")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 120)
                .padding(.horizontal)

                // Duration
                Text(formatDuration(recorder.recordingDuration))
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(recorder.isRecording ? .primary : .secondary)

                // Record / Stop button
                Button {
                    if recorder.isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? .red : .accentColor)
                            .frame(width: 64, height: 64)

                        if recorder.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 22, height: 22)
                        } else {
                            Circle()
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Hint: transcription happens after recording via WhisperKit
                Text("Audio will be transcribed with WhisperKit after recording.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)

            Divider()

            // Options
            Form {
                TextField("Project Title", text: $projectTitle)
                    .onAppear {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd HH:mm"
                        projectTitle = "Recording \(df.string(from: Date()))"
                    }

                Picker("Language", selection: $selectedLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }

                Picker("Whisper Model", selection: $selectedModel) {
                    Text("Tiny (~75MB)").tag("tiny")
                    Text("Base (~140MB)").tag("base")
                    Text("Small (~466MB)").tag("small")
                    Text("Large V3 Turbo (~1.6GB)").tag("large-v3_turbo")
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)

            Divider()

            // Actions
            HStack {
                Spacer()
                Button("Cancel") {
                    recorder.cancelRecording()
                    dismiss()
                }
                Button("Save & Transcribe") {
                    saveRecording()
                }
                .buttonStyle(.borderedProminent)
                .disabled(recorder.isRecording || recorder.outputURL == nil)
            }
            .padding()
        }
        .frame(width: 500, height: 620)
        .task {
            micPermission = AVCaptureDevice.authorizationStatus(for: .audio)
            if micPermission == .notDetermined {
                let granted = await AVCaptureDevice.requestAccess(for: .audio)
                micPermission = granted ? .authorized : .denied
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        guard micPermission == .authorized else {
            errorMessage = String(localized: "Microphone access is required. Please enable it in System Settings > Privacy & Security > Microphone.")
            return
        }

        do {
            try recorder.startRecording()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stopRecording() {
        _ = recorder.stopRecording()
    }

    private func saveRecording() {
        guard let audioURL = recorder.outputURL else { return }

        let title = projectTitle.isEmpty ? "Recording" : projectTitle
        let project = TranscriptionProject(
            title: title,
            sourceType: .audioFile,
            sourceURL: audioURL,
            modelName: selectedModel
        )
        project.language = selectedLanguage.whisperCode
        onCreate(project)
        dismiss()
    }

    // MARK: - Helpers

    private func formatDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 8
        let maxH: CGFloat = 80
        let center = 10.0
        let dist = abs(CGFloat(index) - center) / center
        let level = CGFloat(recorder.audioLevel)
        return base + (maxH - base) * level * (1.0 - dist * 0.6)
    }

    private func barColor(for index: Int) -> Color {
        let level = recorder.audioLevel
        if level > 0.8 { return .red }
        if level > 0.5 { return .orange }
        return .accentColor
    }
}

import SwiftUI
import SwiftData

struct TranscriptionView: View {
    @Bindable var project: TranscriptionProject
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TranscriptionViewModel()
    @State private var playerVM = AudioPlayerViewModel()
    @State private var showTranslation = false
    @State private var showExportSheet = false
    @State private var showSummarySheet = false
    @State private var showTTSControls = false
    @State private var transcriptionTaskID: UUID?
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Main content
            if project.status == .completed {
                completedContent
            } else if project.status == .failed {
                failedContent
            } else {
                processingContent
            }
        }
        .navigationTitle(project.title)
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(project: project)
        }
        .sheet(isPresented: $showSummarySheet) {
            MeetingSummaryView(project: project)
        }
        .onChange(of: project.id) { _, _ in
            loadAudioIfNeeded()
            startTranscriptionIfNeeded()
        }
        .onAppear {
            loadAudioIfNeeded()
            startTranscriptionIfNeeded()
            startTimeUpdater()
        }
        .onDisappear {
            timerTask?.cancel()
            timerTask = nil
        }
    }

    private func startTranscriptionIfNeeded() {
        guard project.status == .importing || project.status == .extractingAudio else { return }
        guard !viewModel.isTranscribing else { return }
        let projectID = project.id
        guard transcriptionTaskID != projectID else { return }
        transcriptionTaskID = projectID
        Task {
            await viewModel.startTranscription(project: project, modelContext: modelContext)
            // After transcription completes, load audio
            loadAudioIfNeeded()
        }
    }

    private func loadAudioIfNeeded() {
        guard project.status == .completed, !playerVM.isLoaded else { return }
        if let url = project.sourceURL {
            playerVM.loadAudio(url: url)
        }
    }

    /// Periodically sync playback time from the player service
    private func startTimeUpdater() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                if playerVM.isLoaded {
                    playerVM.updateTime()
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            // Source type badge
            Label(project.sourceType.displayName, systemImage: project.sourceType.icon)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())

            if let lang = project.language {
                Text(lang.uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            if project.status == .completed {
                // Translation toggle
                Button {
                    showTranslation.toggle()
                } label: {
                    Label("Translation", systemImage: "character.book.closed")
                }
                .help("Toggle translation view")

                // TTS
                Button {
                    showTTSControls.toggle()
                } label: {
                    Label("Read Aloud", systemImage: "speaker.wave.3")
                }
                .help("Text-to-speech")

                // Summary
                Button {
                    showSummarySheet = true
                } label: {
                    Label("Summary", systemImage: "list.clipboard")
                }
                .help("Generate meeting summary")

                // Export
                Button {
                    showExportSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export transcript")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Content States

    private var completedContent: some View {
        VStack(spacing: 0) {
            // Translation controls (if shown)
            if showTranslation {
                TranslationControlBar(project: project)
                Divider()
            }

            // TTS controls (if shown)
            if showTTSControls {
                TTSControlView(project: project)
                Divider()
            }

            // Segment list
            SegmentListView(
                segments: project.sortedSegments,
                showTranslation: showTranslation,
                currentPlaybackTime: playerVM.currentTime,
                onSegmentTap: { segment in
                    playerVM.seek(to: segment.startTime)
                    if !playerVM.isPlaying {
                        playerVM.togglePlayback()
                    }
                }
            )

            Divider()

            // Audio player bar
            AudioPlayerBar(
                project: project,
                playerVM: playerVM
            )
        }
    }

    private var processingContent: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressOverlay(
                status: viewModel.statusMessage.isEmpty ? project.status.displayName : viewModel.statusMessage,
                progress: project.progress
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var failedContent: some View {
        ContentUnavailableView {
            Label("Transcription Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(project.errorMessage ?? String(localized: "An unknown error occurred."))
        } actions: {
            Button("Retry") {
                project.status = .importing
                project.progress = 0
                project.errorMessage = nil
                transcriptionTaskID = nil
                startTranscriptionIfNeeded()
            }
        }
    }
}

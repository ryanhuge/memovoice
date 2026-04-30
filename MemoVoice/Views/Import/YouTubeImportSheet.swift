import SwiftUI

struct YouTubeImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let onComplete: (URL) -> Void

    @State private var progress: Double = 0
    @State private var statusText = String(localized: "Preparing download...")
    @State private var isDownloading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Downloading from YouTube")
                .font(.headline)

            Text(url.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            if isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .frame(width: 300)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack {
                Button("Cancel") { dismiss() }
                if !isDownloading {
                    Button("Download") { startDownload() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(30)
        .frame(width: 400)
    }

    private func startDownload() {
        isDownloading = true
        statusText = String(localized: "Starting download...")
        progress = 0
        errorMessage = nil

        Task {
            do {
                let service = YTDLPService()
                let audioURL = try await service.downloadAudio(
                    from: url,
                    to: FileManager.default.audioDirectory
                ) { fraction, message in
                    Task { @MainActor in
                        progress = fraction
                        statusText = String(localized: String.LocalizationValue(message))
                    }
                }

                await MainActor.run {
                    progress = 1
                    onComplete(audioURL)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isDownloading = false
                }
            }
        }
    }
}

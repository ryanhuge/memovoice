import SwiftUI
import SwiftData

@main
struct MemoVoiceApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appDelegate.pendingFileImport)
        }
        .modelContainer(for: [TranscriptionProject.self])
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 750)

        Settings {
            SettingsView()
        }
    }
}

/// Handles files opened via "Open With" / Finder double-click
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let pendingFileImport = PendingFileImport()

    nonisolated func application(_ application: NSApplication, open urls: [URL]) {
        let audioOrVideo = urls.filter { $0.isAudioFile || $0.isVideoFile }
        guard !audioOrVideo.isEmpty else { return }
        Task { @MainActor in
            self.pendingFileImport.urls.append(contentsOf: audioOrVideo)
        }
    }
}

/// Observable container that passes opened file URLs from AppDelegate to ContentView
@Observable
@MainActor
final class PendingFileImport {
    var urls: [URL] = []

    func consumeNext() -> URL? {
        guard !urls.isEmpty else { return nil }
        return urls.removeFirst()
    }
}

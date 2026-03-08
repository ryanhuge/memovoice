import SwiftUI

struct ToolsSettingsView: View {
    @AppStorage("ffmpegPath") private var ffmpegPath = "/opt/homebrew/bin/ffmpeg"
    @AppStorage("ytdlpPath") private var ytdlpPath = "/opt/homebrew/bin/yt-dlp"
    @AppStorage("claudePath") private var claudePath = "/opt/homebrew/bin/claude"

    @State private var ffmpegInstalled = false
    @State private var ytdlpInstalled = false
    @State private var claudeInstalled = false
    @State private var isInstalling = false
    @State private var installOutput = ""

    var body: some View {
        Form {
            Section("Required Tools") {
                ToolRow(
                    name: "FFmpeg",
                    purpose: "Audio extraction from video files",
                    path: $ffmpegPath,
                    isInstalled: ffmpegInstalled,
                    installAction: { await installTool("ffmpeg") }
                )

                ToolRow(
                    name: "yt-dlp",
                    purpose: "YouTube video/audio download",
                    path: $ytdlpPath,
                    isInstalled: ytdlpInstalled,
                    installAction: { await installTool("yt-dlp") }
                )
            }

            Section("Claude CLI") {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Claude CLI")
                                .fontWeight(.medium)
                            StatusBadge(isInstalled: claudeInstalled)
                        }
                        Text("Translation and summary generation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(claudePath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            if !installOutput.isEmpty {
                Section("Install Log") {
                    ScrollView {
                        Text(installOutput)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                }
            }
        }
        .formStyle(.grouped)
        .task { await checkTools() }
    }

    private func checkTools() async {
        ffmpegInstalled = await checkTool(path: ffmpegPath)
        ytdlpInstalled = await checkTool(path: ytdlpPath)
        claudeInstalled = await checkTool(path: claudePath)
    }

    private func checkTool(path: String) async -> Bool {
        // Resolve symlinks to detect Node.js scripts (e.g. claude → cli.js)
        let resolvedURL = URL(fileURLWithPath: path).resolvingSymlinksInPath()
        let ext = resolvedURL.pathExtension.lowercased()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        if ext == "js" || ext == "mjs" || ext == "cjs" || ext == "ts" {
            // Node.js script — use node interpreter to bypass provenance check
            process.arguments = ["node", resolvedURL.path, "--version"]
        } else {
            // Compiled binary — use env trampoline
            let toolName = URL(fileURLWithPath: path).lastPathComponent
            process.arguments = [toolName, "--version"]
        }

        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        var env = ProcessInfo.processInfo.environment
        let currentPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let extraPaths = ["/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin"]
        let missing = extraPaths.filter { !currentPath.contains($0) }
        if !missing.isEmpty {
            env["PATH"] = (missing + [currentPath]).joined(separator: ":")
        }
        process.environment = env
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func installTool(_ name: String) async {
        isInstalling = true
        installOutput = "Installing \(name) via Homebrew...\n"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        process.arguments = ["install", name]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            installOutput += String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                installOutput += "\n\(name) installed successfully!"
                await checkTools()
            } else {
                installOutput += "\nInstallation failed with exit code \(process.terminationStatus)"
            }
        } catch {
            installOutput += "\nError: \(error.localizedDescription)"
        }

        isInstalling = false
    }
}

struct ToolRow: View {
    let name: String
    let purpose: String
    @Binding var path: String
    let isInstalled: Bool
    let installAction: () async -> Void

    @State private var isInstalling = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                        .fontWeight(.medium)
                    StatusBadge(isInstalled: isInstalled)
                }
                Text(purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isInstalled {
                Text(path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    Task {
                        isInstalling = true
                        await installAction()
                        isInstalling = false
                    }
                } label: {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Install via Homebrew")
                    }
                }
                .controlSize(.small)
            }
        }
    }
}

struct StatusBadge: View {
    let isInstalled: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(isInstalled ? String(localized: "Installed") : String(localized: "Not Found"))
        }
        .font(.caption2)
        .foregroundStyle(isInstalled ? .green : .red)
    }
}

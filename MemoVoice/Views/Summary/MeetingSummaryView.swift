import SwiftUI
import SwiftData
import AppKit

struct MeetingSummaryView: View {
    @Bindable var project: TranscriptionProject
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SummaryViewModel()
    @State private var ttsViewModel = TTSViewModel()
    @State private var selectedTemplate = MeetingTemplate.meetingNotes
    @State private var allTemplates = MeetingTemplate.allTemplates()
    @State private var showExportSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Meeting Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()

            Divider()

            HSplitView {
                // Left: Template picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Template")
                        .font(.headline)

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(allTemplates) { template in
                                Button {
                                    selectedTemplate = template
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            HStack(spacing: 4) {
                                                Text(template.name)
                                                    .fontWeight(selectedTemplate.id == template.id ? .bold : .regular)
                                                if !template.isBuiltIn {
                                                    Text("Custom")
                                                        .font(.caption2)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 1)
                                                        .background(.blue.opacity(0.15))
                                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                                }
                                            }
                                            Text(template.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedTemplate.id == template.id {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(8)
                                .background(selectedTemplate.id == template.id ? Color.accentColor.opacity(0.1) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Generate Summary") {
                        Task {
                            await viewModel.generateSummary(
                                project: project,
                                template: selectedTemplate,
                                modelContext: modelContext
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isGenerating || project.sortedSegments.isEmpty)
                }
                .padding()
                .frame(width: 250)

                // Right: Summary output
                VStack {
                    if viewModel.isGenerating {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text(viewModel.statusMessage.isEmpty ? String(localized: "Generating summary…") : viewModel.statusMessage)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.summary.isEmpty {
                        ContentUnavailableView {
                            Label("No Summary", systemImage: "list.clipboard")
                        } description: {
                            Text("Select a template and click 'Generate Summary'")
                        }
                    } else {
                        ScrollView {
                            Text(viewModel.summary)
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack {
                            if let error = ttsViewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                            Button {
                                if ttsViewModel.isSpeaking {
                                    ttsViewModel.stop()
                                } else {
                                    ttsViewModel.speak(
                                        text: viewModel.summary,
                                        provider: .systemTTS,
                                        voice: ""
                                    )
                                }
                            } label: {
                                Label(ttsViewModel.isSpeaking ? "Stop" : "Read Aloud",
                                      systemImage: ttsViewModel.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                            }
                            .buttonStyle(.bordered)
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(viewModel.summary, forType: .string)
                            }
                            .buttonStyle(.bordered)
                            Button {
                                showExportSheet = true
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .frame(width: 700, height: 500)
        .onAppear {
            if let existing = project.meetingSummary {
                viewModel.summary = existing
            }
        }
        .sheet(isPresented: $showExportSheet) {
            SummaryExportSheet(title: project.title, summary: viewModel.summary)
        }
    }
}

// MARK: - Summary Export Sheet

private struct SummaryExportSheet: View {
    let title: String
    let summary: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: SummaryExportFormat = .markdown
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Export Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            VStack(spacing: 8) {
                ForEach(SummaryExportFormat.allCases) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        HStack {
                            Image(systemName: format.icon)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(format.displayName)
                                    .fontWeight(.medium)
                                Text(".\(format.fileExtension)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(10)
                        .background(selectedFormat == format ? Color.accentColor.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            Spacer()

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Export") { exportFile() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 360, height: 340)
    }

    private func exportFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(title) - Summary.\(selectedFormat.fileExtension)"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            switch selectedFormat {
            case .markdown:
                let content = "# \(title)\n\n## Summary\n\n\(summary)"
                try content.write(to: url, atomically: true, encoding: .utf8)

            case .txt:
                let content = "\(title)\n\nSummary\n\n\(summary)"
                try content.write(to: url, atomically: true, encoding: .utf8)

            case .docx:
                try SummaryDOCXExporter.write(title: title, summary: summary, to: url)
            }

            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum SummaryExportFormat: String, CaseIterable, Identifiable {
    case markdown, txt, docx

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markdown: String(localized: "Markdown (.md)")
        case .txt: String(localized: "Plain Text (.txt)")
        case .docx: String(localized: "Word Document (.docx)")
        }
    }

    var fileExtension: String {
        switch self {
        case .markdown: "md"
        case .txt: "txt"
        case .docx: "docx"
        }
    }

    var icon: String {
        switch self {
        case .markdown: "doc.text"
        case .txt: "doc.plaintext"
        case .docx: "doc.richtext"
        }
    }
}

private enum SummaryDOCXExporter {
    static func write(title: String, summary: String, to url: URL) throws {
        let paragraphs = summary.components(separatedBy: "\n").map { line in
            "<w:p><w:r><w:t xml:space=\"preserve\">\(escapeXML(line))</w:t></w:r></w:p>"
        }.joined(separator: "\n")

        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:body>
                <w:p>
                    <w:pPr><w:pStyle w:val="Title"/></w:pPr>
                    <w:r><w:rPr><w:b/><w:sz w:val="48"/></w:rPr><w:t>\(escapeXML(title))</w:t></w:r>
                </w:p>
                <w:p>
                    <w:r><w:rPr><w:b/><w:sz w:val="28"/></w:rPr><w:t>Summary</w:t></w:r>
                </w:p>
                \(paragraphs)
            </w:body>
        </w:document>
        """

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let wordDir = tempDir.appendingPathComponent("word")
        let relsDir = tempDir.appendingPathComponent("_rels")
        let wordRelsDir = wordDir.appendingPathComponent("_rels")
        try FileManager.default.createDirectory(at: wordDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: wordRelsDir, withIntermediateDirectories: true)

        try contentTypesXML.write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try relsXML.write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try wordRelsXML.write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try xml.write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)

        try? FileManager.default.removeItem(at: url)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", url.path, "."]
        process.currentDirectoryURL = tempDir
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
    </Types>
    """

    private static let relsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
    </Relationships>
    """

    private static let wordRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    </Relationships>
    """
}

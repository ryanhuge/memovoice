import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PendingFileImport.self) private var pendingFileImport
    @Query(sort: \TranscriptionProject.createdAt, order: .reverse) private var projects: [TranscriptionProject]
    @State private var selectedProject: TranscriptionProject?
    @State private var showImportSheet = false
    @State private var showRecordingSheet = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                projects: projects,
                selectedProject: $selectedProject,
                onDelete: deleteProject
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showImportSheet = true
                        } label: {
                            Label("Import File / URL", systemImage: "doc.badge.plus")
                        }
                        Button {
                            showRecordingSheet = true
                        } label: {
                            Label("Record Audio", systemImage: "mic.circle")
                        }
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 350)
        } detail: {
            if let project = selectedProject {
                TranscriptionView(project: project)
            } else {
                WelcomeView(onImport: { showImportSheet = true })
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportView { project in
                addProject(project)
            }
        }
        .sheet(isPresented: $showRecordingSheet) {
            RecordingView { project in
                addProject(project)
            }
        }
        .onDeleteCommand {
            if let project = selectedProject {
                deleteProject(project)
            }
        }
        .onChange(of: pendingFileImport.urls) {
            while let url = pendingFileImport.consumeNext() {
                importFile(url)
            }
        }
    }

    private func addProject(_ project: TranscriptionProject) {
        modelContext.insert(project)
        try? modelContext.save()
        selectedProject = project
    }

    private func importFile(_ url: URL) {
        let title = url.deletingPathExtension().lastPathComponent
        let sourceType: TranscriptionProject.SourceType = url.isVideoFile ? .videoFile : .audioFile
        let project = TranscriptionProject(
            title: title,
            sourceType: sourceType,
            sourceURL: url,
            modelName: AppState.shared.selectedModel
        )
        project.language = SupportedLanguage.zhTW.whisperCode
        addProject(project)
    }

    private func deleteProject(_ project: TranscriptionProject) {
        if selectedProject?.id == project.id {
            selectedProject = nil
        }
        modelContext.delete(project)
        try? modelContext.save()
    }
}

import SwiftUI
import SwiftData

struct SidebarView: View {
    let projects: [TranscriptionProject]
    @Binding var selectedProject: TranscriptionProject?
    let onDelete: (TranscriptionProject) -> Void

    var body: some View {
        List(selection: $selectedProject) {
            if projects.isEmpty {
                ContentUnavailableView {
                    Label("No Projects", systemImage: "waveform")
                } description: {
                    Text("Import an audio or video file to get started.")
                }
            } else {
                ForEach(projects) { project in
                    SidebarRow(project: project)
                        .tag(project)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                onDelete(project)
                            }
                        }
                }
            }
        }
        .navigationTitle("Projects")
    }
}

struct SidebarRow: View {
    let project: TranscriptionProject

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: project.sourceType.icon)
                .foregroundStyle(statusColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if project.status.isProcessing {
                        ProgressView()
                            .controlSize(.mini)
                        Text(project.status.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(project.displayDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let lang = project.language {
                            Text(lang.uppercased())
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch project.status {
        case .completed: .green
        case .failed: .red
        case .transcribing: .orange
        default: .secondary
        }
    }
}

import SwiftUI

struct ExportSheet: View {
    let project: TranscriptionProject
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .srt
    @State private var includeTimecodes = true
    @State private var includeTranslation = false
    @State private var exportVM = ExportViewModel()

    private var hasTranslation: Bool {
        project.sortedSegments.contains { $0.translatedText != nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Transcript")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            // Format selection
            VStack(spacing: 12) {
                ForEach(ExportFormat.allCases) { format in
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

            Divider()

            // Options
            Form {
                if selectedFormat != .srt {
                    Toggle("Include timecodes", isOn: $includeTimecodes)
                }
                if hasTranslation {
                    Toggle("Include translation", isOn: $includeTranslation)
                }
            }
            .formStyle(.grouped)
            .frame(height: 100)

            Divider()

            // Error
            if let error = exportVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            // Actions
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Export") {
                    exportVM.export(
                        project: project,
                        format: selectedFormat,
                        includeTimecodes: includeTimecodes,
                        includeTranslation: includeTranslation
                    )
                    if exportVM.errorMessage == nil {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(exportVM.isExporting)
            }
            .padding()
        }
        .frame(width: 450, height: 480)
    }
}

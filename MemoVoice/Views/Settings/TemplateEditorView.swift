import SwiftUI

struct TemplateEditorView: View {
    @State private var templates = MeetingTemplate.allTemplates()
    @State private var selectedTemplate: MeetingTemplate?
    @State private var editingName = ""
    @State private var editingDescription = ""
    @State private var editingPrompt = ""
    @State private var editingSections = ""

    var body: some View {
        HSplitView {
            // Template list
            VStack(alignment: .leading) {
                List(selection: $selectedTemplate) {
                    ForEach(templates) { template in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(template.name)
                                    .fontWeight(.medium)
                                if template.isBuiltIn {
                                    Text("Built-in")
                                        .font(.caption2)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(.quaternary)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                            }
                            Text(template.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(template)
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)

                HStack {
                    Button {
                        addTemplate()
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        if let selected = selectedTemplate, !selected.isBuiltIn {
                            deleteTemplate(selected)
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedTemplate?.isBuiltIn ?? true)
                }
                .padding(8)
            }
            .frame(minWidth: 200, maxWidth: 250)

            // Editor
            if let template = selectedTemplate {
                Form {
                    Section("Template Details") {
                        TextField("Name", text: $editingName)
                        TextField("Description", text: $editingDescription)
                    }

                    Section("Sections (comma separated)") {
                        TextField("Sections", text: $editingSections)
                    }

                    Section("System Prompt") {
                        TextEditor(text: $editingPrompt)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 150)
                    }

                    if !template.isBuiltIn {
                        Section {
                            Button("Save Changes") {
                                saveTemplate()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .formStyle(.grouped)
                .onChange(of: selectedTemplate) { _, newTemplate in
                    if let t = newTemplate {
                        loadEditing(t)
                    }
                }
                .onAppear {
                    loadEditing(template)
                }
                .disabled(template.isBuiltIn)
            } else {
                ContentUnavailableView("Select a Template", systemImage: "doc.text")
            }
        }
    }

    private func loadEditing(_ template: MeetingTemplate) {
        editingName = template.name
        editingDescription = template.description
        editingPrompt = template.systemPrompt
        editingSections = template.sections.joined(separator: ", ")
    }

    private func addTemplate() {
        let template = MeetingTemplate(
            id: UUID(),
            name: String(localized: "New Template"),
            description: String(localized: "Custom meeting template"),
            systemPrompt: "Summarize the following meeting transcript:",
            sections: ["Summary"],
            isBuiltIn: false,
            createdAt: Date()
        )
        templates.append(template)
        selectedTemplate = template
        MeetingTemplate.saveCustomTemplates(templates)
    }

    private func deleteTemplate(_ template: MeetingTemplate) {
        templates.removeAll { $0.id == template.id }
        selectedTemplate = nil
        MeetingTemplate.saveCustomTemplates(templates)
    }

    private func saveTemplate() {
        guard let index = templates.firstIndex(where: { $0.id == selectedTemplate?.id }) else { return }
        templates[index].name = editingName
        templates[index].description = editingDescription
        templates[index].systemPrompt = editingPrompt
        templates[index].sections = editingSections.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        selectedTemplate = templates[index]
        MeetingTemplate.saveCustomTemplates(templates)
    }
}

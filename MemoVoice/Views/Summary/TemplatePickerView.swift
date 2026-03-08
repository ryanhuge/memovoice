import SwiftUI

struct TemplatePickerView: View {
    @Binding var selectedTemplate: MeetingTemplate
    let templates: [MeetingTemplate]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(templates) { template in
                Button {
                    selectedTemplate = template
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .fontWeight(.medium)
                            Text(template.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedTemplate.id == template.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding(8)
                    .background(selectedTemplate.id == template.id ? Color.accentColor.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

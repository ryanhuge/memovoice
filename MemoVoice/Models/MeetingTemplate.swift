import Foundation

struct MeetingTemplate: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var systemPrompt: String
    var sections: [String]
    var isBuiltIn: Bool
    var createdAt: Date

    static let meetingNotes = MeetingTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Meeting Notes",
        description: "Standard meeting notes with key points and action items",
        systemPrompt: """
        You are a meeting notes assistant. Given the following transcript, create structured meeting notes with these sections: \
        Summary, Key Discussion Points, Decisions Made, Action Items (with assignees if mentioned), and Next Steps. \
        Be concise but thorough. Use bullet points. Output in the same language as the transcript.
        """,
        sections: ["Summary", "Key Discussion Points", "Decisions Made", "Action Items", "Next Steps"],
        isBuiltIn: true,
        createdAt: Date()
    )

    static let actionItems = MeetingTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Action Items",
        description: "Extract action items with owners and deadlines",
        systemPrompt: """
        You are an action item extractor. Given the following meeting transcript, identify all action items. \
        For each item, list: the task description, the person responsible (if mentioned), and the deadline (if mentioned). \
        Format as a numbered list. Output in the same language as the transcript.
        """,
        sections: ["Action Items"],
        isBuiltIn: true,
        createdAt: Date()
    )

    static let standup = MeetingTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Daily Standup",
        description: "Standup summary: done, doing, blockers",
        systemPrompt: """
        You are a standup meeting summarizer. Given the following standup transcript, summarize for each participant: \
        What they completed yesterday, what they plan to do today, and any blockers. \
        Use a clear format with participant names as headers. Output in the same language as the transcript.
        """,
        sections: ["Yesterday", "Today", "Blockers"],
        isBuiltIn: true,
        createdAt: Date()
    )

    static let builtInTemplates: [MeetingTemplate] = [meetingNotes, actionItems, standup]

    // MARK: - Custom template persistence

    private static let customTemplatesKey = "customMeetingTemplates"

    static func loadCustomTemplates() -> [MeetingTemplate] {
        guard let data = UserDefaults.standard.data(forKey: customTemplatesKey) else { return [] }
        return (try? JSONDecoder().decode([MeetingTemplate].self, from: data)) ?? []
    }

    static func saveCustomTemplates(_ templates: [MeetingTemplate]) {
        let customs = templates.filter { !$0.isBuiltIn }
        if let data = try? JSONEncoder().encode(customs) {
            UserDefaults.standard.set(data, forKey: customTemplatesKey)
        }
    }

    /// All templates: built-in + user custom
    static func allTemplates() -> [MeetingTemplate] {
        builtInTemplates + loadCustomTemplates()
    }
}

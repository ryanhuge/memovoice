import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case srt
    case docx
    case txt
    case markdown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .srt: String(localized: "SRT Subtitle")
        case .docx: String(localized: "Word Document (.docx)")
        case .txt: String(localized: "Plain Text (.txt)")
        case .markdown: String(localized: "Markdown (.md)")
        }
    }

    var fileExtension: String {
        switch self {
        case .srt: "srt"
        case .docx: "docx"
        case .txt: "txt"
        case .markdown: "md"
        }
    }

    var icon: String {
        switch self {
        case .srt: "captions.bubble"
        case .docx: "doc.richtext"
        case .txt: "doc.plaintext"
        case .markdown: "doc.text"
        }
    }

    var utType: String {
        switch self {
        case .srt: "com.memovoice.srt"
        case .docx: "org.openxmlformats.wordprocessingml.document"
        case .txt: "public.plain-text"
        case .markdown: "net.daringfireball.markdown"
        }
    }
}

import Foundation

enum TranslationProvider: String, CaseIterable, Identifiable {
    case claudeCLI = "claude-cli"
    case openAI = "openai"
    case gemini = "gemini"
    case deepSeek = "deepseek"
    case openRouter = "openrouter"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCLI: String(localized: "Claude CLI")
        case .openAI: String(localized: "OpenAI")
        case .gemini: String(localized: "Google Gemini")
        case .deepSeek: String(localized: "DeepSeek")
        case .openRouter: String(localized: "OpenRouter")
        }
    }

    var icon: String {
        switch self {
        case .claudeCLI: "terminal"
        case .openAI: "brain"
        case .gemini: "sparkles"
        case .deepSeek: "magnifyingglass"
        case .openRouter: "network"
        }
    }

    var requiresAPIKey: Bool {
        self != .claudeCLI
    }

    var keychainKey: String {
        "com.memovoice.apikey.\(rawValue)"
    }
}

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case auto = "auto"
    case en = "en"
    case zhTW = "zh-TW"
    case zhCN = "zh-CN"
    case ja = "ja"
    case ko = "ko"
    case fr = "fr"
    case de = "de"
    case es = "es"
    case pt = "pt"
    case ru = "ru"
    case ar = "ar"
    case hi = "hi"
    case th = "th"
    case vi = "vi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: String(localized: "Auto Detect")
        case .en: String(localized: "English")
        case .zhTW: "繁體中文"
        case .zhCN: "简体中文"
        case .ja: "日本語"
        case .ko: "한국어"
        case .fr: "Français"
        case .de: "Deutsch"
        case .es: "Español"
        case .pt: "Português"
        case .ru: "Русский"
        case .ar: "العربية"
        case .hi: "हिन्दी"
        case .th: "ไทย"
        case .vi: "Tiếng Việt"
        }
    }

    var whisperCode: String? {
        self == .auto ? nil : rawValue.components(separatedBy: "-").first
    }
}

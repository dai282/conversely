import Foundation

/// A conversation language: BCP-47 locale plus display metadata.
/// Distinct from the app's own UI display language (PRD §6.1).
struct Language: Identifiable, Hashable {
    let id: String // e.g. "en-US"
    let flag: String
    let englishName: String
    let localizedName: String

    /// The language's name in whatever UI language is showing, so switching
    /// the app to Vietnamese renames "Spanish" to "Tiếng Tây Ban Nha" without
    /// needing a hand-written name per UI language. Only the language code is
    /// used — `forIdentifier` would yield "Vietnamese (Vietnam)".
    func name(in locale: Locale) -> String {
        guard let code = Locale.Language(identifier: id).languageCode?.identifier,
              let name = locale.localizedString(forLanguageCode: code) else {
            return englishName
        }
        return name
    }

    static let english = Language(id: "en-US", flag: "🇺🇸", englishName: "English", localizedName: "English")
    static let vietnamese = Language(id: "vi-VN", flag: "🇻🇳", englishName: "Vietnamese", localizedName: "Tiếng Việt")
    static let spanish = Language(id: "es-ES", flag: "🇪🇸", englishName: "Spanish", localizedName: "Español")
    static let french = Language(id: "fr-FR", flag: "🇫🇷", englishName: "French", localizedName: "Français")
    static let german = Language(id: "de-DE", flag: "🇩🇪", englishName: "German", localizedName: "Deutsch")
    static let japanese = Language(id: "ja-JP", flag: "🇯🇵", englishName: "Japanese", localizedName: "日本語")
    // Russian is deliberately absent: neither speech engine can transcribe it
    // on-device (`SpeechTranscriber` has no ru model, and the legacy
    // recognizer's Assistant asset isn't installable from an app), so it could
    // only ever be a translation target — useless for a spoken conversation.
    static let chinese = Language(id: "zh-Hans-CN", flag: "🇨🇳", englishName: "Chinese (Simplified)", localizedName: "简体中文")
}

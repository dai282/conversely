import Foundation

/// A conversation language: BCP-47 locale plus display metadata.
/// Distinct from the app's own UI display language (PRD §6.1).
struct Language: Identifiable, Hashable {
    let id: String // e.g. "en-US"
    let flag: String
    let englishName: String
    let localizedName: String

    static let english = Language(id: "en-US", flag: "🇺🇸", englishName: "English", localizedName: "English")
    static let vietnamese = Language(id: "vi-VN", flag: "🇻🇳", englishName: "Vietnamese", localizedName: "Tiếng Việt")
    static let spanish = Language(id: "es-ES", flag: "🇪🇸", englishName: "Spanish", localizedName: "Español")
    static let french = Language(id: "fr-FR", flag: "🇫🇷", englishName: "French", localizedName: "Français")
    static let german = Language(id: "de-DE", flag: "🇩🇪", englishName: "German", localizedName: "Deutsch")
    static let japanese = Language(id: "ja-JP", flag: "🇯🇵", englishName: "Japanese", localizedName: "日本語")
    static let russian = Language(id: "ru-RU", flag: "🇷🇺", englishName: "Russian", localizedName: "Русский")
    static let chinese = Language(id: "zh-Hans-CN", flag: "🇨🇳", englishName: "Chinese (Simplified)", localizedName: "简体中文")
}

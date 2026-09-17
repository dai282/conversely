import Foundation

/// The app's own UI language (button labels, screen titles) — fully decoupled
/// from the conversation languages picked on Screen 1. Backed by a String
/// Catalog once localization lands (DEVELOPMENT_PLAN.md, Phase 5). See PRD §6.1.
struct DisplayLanguage: Identifiable, Hashable {
    let id: String // BCP-47
    let flag: String
    let englishName: String

    static let supported: [DisplayLanguage] = [
        DisplayLanguage(id: "en", flag: "🇺🇸", englishName: "English"),
        DisplayLanguage(id: "es", flag: "🇪🇸", englishName: "Spanish"),
        DisplayLanguage(id: "fr", flag: "🇫🇷", englishName: "French"),
        DisplayLanguage(id: "de", flag: "🇩🇪", englishName: "German"),
        DisplayLanguage(id: "vi", flag: "🇻🇳", englishName: "Vietnamese"),
        DisplayLanguage(id: "ja", flag: "🇯🇵", englishName: "Japanese"),
    ]

    static let english = supported[0]
}

import Foundation

/// The app's own UI language (button labels, screen titles) — fully decoupled
/// from the conversation languages picked on Screen 1. Backed by
/// `Resources/Localizable.xcstrings`. See PRD §6.1.
///
/// This list is deliberately only what the String Catalog actually contains:
/// offering a language the catalog can't serve would just switch the UI to
/// English under a different flag.
struct DisplayLanguage: Identifiable, Hashable {
    let id: String // BCP-47
    let flag: String
    let englishName: String

    static let supported: [DisplayLanguage] = [
        DisplayLanguage(id: "en", flag: "🇺🇸", englishName: "English"),
        DisplayLanguage(id: "vi", flag: "🇻🇳", englishName: "Vietnamese"),
    ]

    static let english = supported[0]

    var locale: Locale { Locale(identifier: id) }

    /// The language's name in whichever UI language is showing, so the menu
    /// reads "Tiếng Anh / Tiếng Việt" in Vietnamese rather than staying
    /// English. Falls back to the hardcoded name if the system has no
    /// translation for the pair.
    func name(in locale: Locale) -> String {
        locale.localizedString(forLanguageCode: id) ?? englishName
    }
}

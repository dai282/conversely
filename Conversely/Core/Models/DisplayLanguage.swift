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

    /// Each language named in itself — "English", "Tiếng Việt" — never
    /// translated into whichever UI language happens to be showing. Someone
    /// switching away from a language they can't read needs to recognise
    /// their own language in the list, which "Tiếng Anh" wouldn't help with.
    var nativeName: String {
        locale.localizedString(forLanguageCode: id) ?? englishName
    }
}

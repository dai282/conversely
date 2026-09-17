import SwiftUI

/// Owns the app's UI display language (PRD §6.1) and persists it across
/// launches.
///
/// The switch takes effect immediately rather than on next launch: the root
/// view publishes the selection through SwiftUI's `\.locale` environment
/// value, which is what `Text` resolves String Catalog keys against. The
/// alternative — rewriting `AppleLanguages` in `UserDefaults` — only applies
/// after the app restarts, which is a poor thing to ask of someone who just
/// wanted to read the buttons.
///
/// The consequence to remember: strings must be built where the environment
/// is readable. `Text("Speak \(name)")` localizes; a `String` assembled in a
/// view model does not.
@MainActor
final class AppLocalization: ObservableObject {
    @Published var language: DisplayLanguage {
        didSet { UserDefaults.standard.set(language.id, forKey: Self.storageKey) }
    }

    private static let storageKey = "displayLanguage"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        language = DisplayLanguage.supported.first { $0.id == stored }
            ?? Self.matchingSystemLanguage()
            ?? .english
    }

    /// First launch follows the phone: someone whose device is in Vietnamese
    /// shouldn't have to go find the switcher.
    private static func matchingSystemLanguage() -> DisplayLanguage? {
        guard let code = Locale.preferredLanguages.first.map({
            Locale(identifier: $0).language.languageCode?.identifier
        }) ?? nil else { return nil }
        return DisplayLanguage.supported.first { $0.id == code }
    }
}

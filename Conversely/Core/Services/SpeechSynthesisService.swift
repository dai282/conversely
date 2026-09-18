import AVFoundation

/// Wraps `AVSpeechSynthesizer` to speak a translation aloud immediately after
/// it's produced, and to replay it on demand from a bubble's replay button
/// (PRD §6, requirements 5-6).
final class SpeechSynthesisService {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, locale: Locale) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.bestVoice(for: locale)
        synthesizer.stopSpeaking(at: .word)
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// The best voice installed for a locale — without losing the region.
    ///
    /// **Why this isn't a plain quality scan any more.** The first version
    /// filtered `speechVoices()` on the language code alone and took
    /// `max(by: quality)`. But every voice a device ships with is `.default`
    /// quality, so that comparison always tied, and `max(by:)` keeps the
    /// *first* of equal elements — i.e. whatever order the system happened to
    /// return. Replaying it against the installed catalogue: `fr-FR` came back
    /// as `fr-CA` "Amélie" and `zh-Hans-CN` as `zh-TW` "Meijia", so French was
    /// read aloud in a Québécois accent and Simplified Chinese in a Taiwanese
    /// one. `en-US`, `vi-VN`, `es-ES`, `de-DE` and `ja-JP` were right only by
    /// luck of ordering.
    ///
    /// So start from `AVSpeechSynthesisVoice(language:)`, which resolves region
    /// *and* script correctly (`zh-Hans-CN` → `zh-CN` "Tingting"), rather than
    /// re-deriving that here. The second pass exists because that initialiser
    /// is documented to return enhanced-if-available but never `.premium`, so
    /// a user who has downloaded a premium voice would otherwise never hear it.
    ///
    /// Note this can only pick between *installed* voices, and a stock device
    /// has nothing but `.default` ones — Siri's neural voices, which Apple's
    /// own Translate app uses, are excluded from `speechVoices()` and rejected
    /// by `voiceWithIdentifier:`, with no entitlement available to a
    /// third-party app. Quality beyond `.default` needs the user to download
    /// an Enhanced/Premium voice in Settings.
    ///
    /// Returns nil if no voice is installed at all — the caller (or the
    /// Language Management screen, Phase 3) should treat that as a gap and
    /// point the user at Settings > Accessibility > Spoken Content > Voices.
    static func bestVoice(for locale: Locale) -> AVSpeechSynthesisVoice? {
        guard let systemChoice = AVSpeechSynthesisVoice(language: locale.identifier) else {
            return fallbackVoice(for: locale)
        }
        let upgrade = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == systemChoice.language && isUsable($0) }
            .max { $0.quality.rawValue < $1.quality.rawValue }
        guard let upgrade, upgrade.quality.rawValue > systemChoice.quality.rawValue else {
            return systemChoice
        }
        return upgrade
    }

    /// Only reached when the system has no voice for the locale's exact tag.
    /// Prefers one from the same region, then any sharing the language code —
    /// a wrong-accent voice still beats silence.
    private static func fallbackVoice(for locale: Locale) -> AVSpeechSynthesisVoice? {
        let language = Locale.Language(identifier: locale.identifier)
        guard let languageCode = language.languageCode?.identifier else { return nil }

        let candidates = AVSpeechSynthesisVoice.speechVoices().filter {
            Locale.Language(identifier: $0.language).languageCode?.identifier == languageCode
                && isUsable($0)
        }
        let sameRegion = candidates.filter {
            Locale.Language(identifier: $0.language).region == language.region
        }
        let pool = sameRegion.isEmpty ? candidates : sameRegion
        return pool.max { $0.quality.rawValue < $1.quality.rawValue }
    }

    /// Novelty voices ("Bells", "Zarvox") and the user's Personal Voice are
    /// both in `speechVoices()` and have no business reading a translation
    /// aloud. They're all `.default` quality, so they can't win the upgrade
    /// pass — but they can win the fallback, and cost nothing to exclude.
    private static func isUsable(_ voice: AVSpeechSynthesisVoice) -> Bool {
        voice.voiceTraits.isDisjoint(with: [.isNoveltyVoice, .isPersonalVoice])
    }
}

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

    /// Prefers the highest-quality voice installed offline for the locale.
    /// Returns nil if no voice is installed at all — the caller (or the
    /// Language Management screen, Phase 3) should treat that as a gap and
    /// point the user at Settings > Accessibility > Spoken Content > Voices.
    static func bestVoice(for locale: Locale) -> AVSpeechSynthesisVoice? {
        guard let languageCode = locale.language.languageCode?.identifier else {
            return AVSpeechSynthesisVoice(language: locale.identifier)
        }
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(languageCode) }
        return candidates.max(by: { $0.quality.rawValue < $1.quality.rawValue })
            ?? AVSpeechSynthesisVoice(language: locale.identifier)
    }
}

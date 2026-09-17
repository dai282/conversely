import Foundation

/// Status of one on-device component (STT, Translation, or TTS voice) for a language.
/// A language is only "usable" once all three are `.downloaded` (PRD §5.2, §7).
///
/// These are deliberately *not* surfaced individually in the UI. Which of the
/// three legs is missing is an implementation detail the user can't act on
/// differently — the Download button fetches whatever is missing — so the
/// Languages screen shows only whether a language works or not.
enum ComponentStatus: Hashable {
    case unavailable       // no on-device support exists for this locale at all
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
}

struct LanguagePackStatus: Identifiable, Hashable {
    let language: Language
    var speech: ComponentStatus
    var translation: ComponentStatus
    var voice: ComponentStatus
    var approximateSizeMB: Int

    var id: String { language.id }

    var isFullyReady: Bool {
        speech == .downloaded && translation == .downloaded && voice == .downloaded
    }

    var isInProgress: Bool { downloadProgress != nil }

    /// Fractional progress while something is downloading. Only the speech
    /// asset reports real progress — the Translation pack's download is
    /// driven by the system's own sheet, which owns its own progress UI.
    var downloadProgress: Double? {
        for status in [speech, translation, voice] {
            if case .downloading(let progress) = status { return progress }
        }
        return nil
    }

    /// A leg with no on-device support at all, which no download can fix.
    /// None of the currently offered languages are in this state; it's the
    /// honest fallback if that ever changes (see `Language.swift` on Russian).
    var hasGap: Bool {
        [speech, translation, voice].contains(.unavailable)
    }
}

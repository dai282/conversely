import Foundation

/// Status of one on-device component (STT, Translation, or TTS voice) for a language.
/// A language is only "usable" once all three are `.downloaded` (PRD §5.2, §7).
enum ComponentStatus: Hashable {
    case unavailable       // no on-device support exists for this locale at all
    case notDownloaded
    case queued
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

    var isInProgress: Bool {
        [speech, translation, voice].contains {
            if case .downloading = $0 { return true }
            return $0 == .queued
        }
    }

    var hasGap: Bool {
        [speech, translation, voice].contains(.unavailable)
    }
}

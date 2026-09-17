import Foundation
import Speech
import AVFoundation
import Translation
import UIKit

/// Drives Screen 2 with real per-component status (Phase 3,
/// DEVELOPMENT_PLAN.md — replaces the Phase 0 mock booleans).
///
/// **API reality check, not a design choice:** of the three components,
/// only Translation can actually be *downloaded* by a third-party app
/// (`TranslationSession.prepareTranslation()`, which shows the system's own
/// download sheet). On-device Speech recognition models and TTS voices are
/// system-managed — there is no public API to download or delete either one
/// from inside an app; the user manages both in iOS Settings. So:
/// - Speech / Voice: detected only (`.downloaded` or `.unavailable`), never
///   `.notDownloaded` — there's nothing this app can do to change that
///   status, so a "download" affordance for them would be fake UI.
/// - Translation: fully real — `.notDownloaded` is downloadable via
///   `startDownload`, which triggers the system prompt.
/// - Delete: removed entirely. None of the three components can be deleted
///   from a third-party app; a Delete button that didn't actually delete
///   anything would be worse than not having one. `openSystemSettings()`
///   is the honest alternative for both gaps and cleanup.
@MainActor
final class LanguageManagementViewModel: ObservableObject {
    @Published private(set) var packs: [LanguagePackStatus] = []
    @Published var displayLanguage: DisplayLanguage = .english
    @Published private(set) var pendingDownloadConfiguration: TranslationSession.Configuration?

    /// Every conversation pair in this MVP includes English by default, and
    /// Translation framework availability is inherently pairwise rather than
    /// a property of a single language — this is the fixed pivot each
    /// candidate language's status is checked against.
    private let pivotLanguageID = "en-US"
    private let candidateLanguages: [Language] = [.english, .vietnamese, .spanish, .french, .german, .japanese]

    init() {
        Task { await refreshAllStatuses() }
    }

    var downloadedPacks: [LanguagePackStatus] { packs.filter(\.isFullyReady) }
    var availablePacks: [LanguagePackStatus] { packs.filter { !$0.isFullyReady } }

    func refreshAllStatuses() async {
        var updated: [LanguagePackStatus] = []
        for language in candidateLanguages {
            updated.append(await status(for: language))
        }
        packs = updated
    }

    private func status(for language: Language) async -> LanguagePackStatus {
        let locale = Locale(identifier: language.id)

        let speech: ComponentStatus = (SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition ?? false)
            ? .downloaded
            : .unavailable

        let languageCode = locale.language.languageCode?.identifier ?? language.id
        let voice: ComponentStatus = AVSpeechSynthesisVoice.speechVoices().contains { $0.language.hasPrefix(languageCode) }
            ? .downloaded
            : .unavailable

        let translation: ComponentStatus
        if language.id == pivotLanguageID {
            // English-to-English isn't a meaningful pair; the pivot is
            // trivially "ready" for translation purposes.
            translation = .downloaded
        } else {
            switch await LanguageAvailability().status(from: .init(identifier: pivotLanguageID), to: .init(identifier: language.id)) {
            case .installed: translation = .downloaded
            case .supported: translation = .notDownloaded
            case .unsupported: translation = .unavailable
            @unknown default: translation = .unavailable
            }
        }

        return LanguagePackStatus(
            language: language,
            speech: speech,
            translation: translation,
            voice: voice,
            approximateSizeMB: Self.approximateSizeMB[language.id] ?? 0
        )
    }

    /// Hosts a one-off `TranslationSession` (via `LanguageManagementView`'s
    /// `.translationTask`) and calls `prepareTranslation()` on it, which
    /// shows the system's own download sheet for this language pair.
    func startDownload(for id: String) {
        guard id != pivotLanguageID else { return }
        pendingDownloadConfiguration = .init(source: .init(identifier: pivotLanguageID), target: .init(identifier: id))
    }

    /// Called by the hosting view once `.translationTask` vends the session
    /// for `pendingDownloadConfiguration`.
    func handleDownloadSession(_ session: TranslationSession) async {
        defer { pendingDownloadConfiguration = nil }
        do {
            try await session.prepareTranslation()
        } catch {
            print("Translation download failed: \(error)")
        }
        await refreshAllStatuses()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func setDisplayLanguage(_ language: DisplayLanguage) {
        displayLanguage = language
    }

    /// Translation framework exposes no public API for a pack's actual
    /// download size (PRD §10's "storage footprint" risk is still open) —
    /// these are rough placeholder estimates, not measured values.
    private static let approximateSizeMB: [String: Int] = [
        "en-US": 380, "vi-VN": 410, "es-ES": 395, "fr-FR": 420, "de-DE": 405, "ja-JP": 490,
    ]
}

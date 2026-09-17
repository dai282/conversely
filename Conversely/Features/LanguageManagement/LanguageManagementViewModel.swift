import Foundation
import Speech
import AVFoundation
import Translation
import UIKit

/// Drives Screen 2 with real per-component status (Phase 3,
/// DEVELOPMENT_PLAN.md — replaces the Phase 0 mock booleans).
///
/// **What this app can and can't install**, which is what shapes the whole
/// screen:
/// - **Translation** — downloadable via `TranslationSession.prepareTranslation()`,
///   which shows the system's own download sheet (and owns its progress UI).
/// - **Speech** — downloadable on iOS 26 via `SpeechAssetService`/`AssetInventory`,
///   with real progress this app reports itself. Languages the legacy
///   recognizer covers but `SpeechTranscriber` doesn't (Vietnamese) depend on
///   a system-managed asset instead; see `SpeechAssetService`'s doc comment.
/// - **Voice** — system-managed, detected only. In practice every offered
///   language already has one.
/// - **Delete** — not possible from a third-party app for any of the three.
///   A Delete button that didn't delete anything would be worse than none, so
///   `openSystemSettings()` is the honest alternative.
///
/// The per-component breakdown stays internal: it decides `isFullyReady`, and
/// therefore which languages the conversation screen offers, but the UI shows
/// only whether a language works — the user can't act on one leg at a time.
@MainActor
final class LanguageManagementViewModel: ObservableObject {
    @Published private(set) var packs: [LanguagePackStatus] = []
    @Published var displayLanguage: DisplayLanguage = .english
    @Published private(set) var pendingDownloadConfiguration: TranslationSession.Configuration?

    /// Live fractional progress for speech-asset installs, keyed by language
    /// id. Unlike the Translation download (whose progress the system's own
    /// sheet owns), this one is ours to report.
    @Published private(set) var speechDownloadProgress: [String: Double] = [:]

    /// Every conversation pair in this MVP includes English by default, and
    /// Translation framework availability is inherently pairwise rather than
    /// a property of a single language — this is the fixed pivot each
    /// candidate language's status is checked against.
    private let pivotLanguageID = "en-US"
    private let candidateLanguages: [Language] = [
        .english, .vietnamese, .spanish, .french, .german, .japanese, .chinese,
    ]

    init() {
        Task {
            await refreshAllStatuses()
            // `LanguageAvailability` can under-report an already-installed
            // pair as merely `.supported` right at cold launch — its
            // backing service seems to need a moment to finish warming up.
            // A quick recheck a beat later self-heals this so the user
            // doesn't have to pull-to-refresh to see a language they've
            // already downloaded.
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await refreshAllStatuses()
        }
    }

    var downloadedPacks: [LanguagePackStatus] { packs.filter(\.isFullyReady) }
    var availablePacks: [LanguagePackStatus] { packs.filter { !$0.isFullyReady } }

    func refreshAllStatuses() async {
        // Fetched once per refresh rather than per language: `speechVoices()`
        // enumerates every installed voice on the device, and does it
        // synchronously (see `installedVoiceLanguages`).
        let voiceLanguages = await Self.installedVoiceLanguages()
        var updated: [LanguagePackStatus] = []
        for language in candidateLanguages {
            updated.append(await status(for: language, voiceLanguages: voiceLanguages))
        }
        packs = updated
    }

    private func status(for language: Language, voiceLanguages: [String]) async -> LanguagePackStatus {
        let locale = Locale(identifier: language.id)
        let speech = await speechStatus(for: locale, languageID: language.id)

        let languageCode = locale.language.languageCode?.identifier ?? language.id
        let voice: ComponentStatus = voiceLanguages.contains { $0.hasPrefix(languageCode) }
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

    /// Union of the two speech engines, because they cover different
    /// languages and have separate asset families (see
    /// `SpeechAssetService`). Order matters: the legacy Assistant asset
    /// being present is enough on its own (that's how Vietnamese works,
    /// which `SpeechTranscriber` doesn't support at all), and only if it
    /// isn't do we consult the iOS 26 inventory — which, unlike the legacy
    /// one, can report a `.notDownloaded` state this app can actually act on.
    private func speechStatus(for locale: Locale, languageID: String) async -> ComponentStatus {
        if let progress = speechDownloadProgress[languageID] {
            return .downloading(progress: progress)
        }
        if await SpeechRecognitionService.legacyOnDeviceSupport(for: locale) {
            return .downloaded
        }
        guard #available(iOS 26.0, *) else { return .unavailable }
        switch await SpeechAssetService().status(for: locale) {
        case .installed: return .downloaded
        case .downloading: return .downloading(progress: 0)
        case .notInstalled: return .notDownloaded
        case .unsupported: return .unavailable
        }
    }

    /// Downloads everything a language needs: the Translation pack (via a
    /// one-off `TranslationSession` hosted by `LanguageManagementView`'s
    /// `.translationTask`, which shows the system's own sheet) *and* the
    /// on-device speech asset (via `AssetInventory`, which is ours to drive
    /// and report progress for).
    func startDownload(for id: String) {
        startSpeechAssetDownload(for: id)

        guard id != pivotLanguageID else { return }
        let configuration = TranslationSession.Configuration(
            source: .init(identifier: pivotLanguageID),
            target: .init(identifier: id)
        )

        // `.translationTask` only restarts when its configuration actually
        // changes. If the previous attempt's session never resolved (the
        // user dismissed the system sheet instead of completing or
        // explicitly cancelling it, so `handleDownloadSession` is still
        // suspended in `prepareTranslation()`), `pendingDownloadConfiguration`
        // never got reset to nil -- so pressing Download again for the same
        // language would reassign an equal value and silently do nothing.
        // Routing through nil first guarantees SwiftUI sees a real
        // transition and retriggers the task regardless of stuck state.
        pendingDownloadConfiguration = nil
        Task { @MainActor in
            self.pendingDownloadConfiguration = configuration
        }
    }

    private func startSpeechAssetDownload(for id: String) {
        guard #available(iOS 26.0, *) else { return }
        guard speechDownloadProgress[id] == nil else { return }

        let locale = Locale(identifier: id)
        let service = SpeechAssetService()

        Task {
            guard await service.status(for: locale) == .notInstalled else { return }
            speechDownloadProgress[id] = 0

            do {
                try await service.install(locale: locale) { fraction in
                    Task { @MainActor in
                        self.speechDownloadProgress[id] = fraction
                    }
                }
                await service.reserveIfPossible(locale: locale)
            } catch {
                print("Speech asset install failed for \(id): \(error)")
            }

            speechDownloadProgress[id] = nil
            await refreshAllStatuses()
        }
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

    /// `speechVoices()` blocks while it walks the installed voice catalogue.
    /// Same reasoning as `SpeechRecognitionService.legacyOnDeviceSupport` —
    /// off the cooperative pool so it can't stall the main thread mid-refresh.
    private static func installedVoiceLanguages() async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: AVSpeechSynthesisVoice.speechVoices().map(\.language))
            }
        }
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
        "en-US": 380, "vi-VN": 410, "es-ES": 395, "fr-FR": 420,
        "de-DE": 405, "ja-JP": 490, "zh-Hans-CN": 460,
    ]
}

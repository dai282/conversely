import Foundation
import Speech

/// Wraps iOS 26's `AssetInventory` so the app can install on-device speech
/// assets itself instead of telling the user to add a keyboard in Settings
/// and hope the background download eventually lands.
///
/// **Why this exists (diagnosed on-device, Phase 4):** there are two
/// separate speech asset families.
/// - `SFSpeechRecognizer.supportsOnDeviceRecognition` reads the legacy
///   *Assistant* (Siri/dictation) asset. Only Settings triggers that one;
///   no public API can install it. That's why Spanish silently flipped to
///   `true` hours after its keyboard was added, and why French stayed
///   `false` no matter what.
/// - `SpeechTranscriber` + `AssetInventory` (iOS 26) use their own assets,
///   which *are* installable on demand with real progress reporting.
///   Installing one does nothing for the other — verified: after
///   `downloadAndInstall()` put `fr_FR` in `installedLocales`,
///   `supportsOnDeviceRecognition("fr-FR")` was still `false`.
///
/// Coverage differs too: `SpeechTranscriber` handles ~30 locales (de, en,
/// es, fr, it, ja, ko, pt, yue, zh) and notably *not* Vietnamese, which only
/// works via the legacy recognizer. So the app takes the union of both —
/// see `SpeechRecognitionService`.
@available(iOS 26.0, *)
struct SpeechAssetService {
    enum AssetStatus {
        /// `SpeechTranscriber` can't handle this locale at all.
        case unsupported
        /// Installable on demand via `install(locale:onProgress:)`.
        case notInstalled
        case downloading
        case installed
    }

    /// `SpeechTranscriber` works in canonical locales (`fr_FR`, `zh_CN`);
    /// nil means it has no model for this language in any region.
    func canonicalLocale(for locale: Locale) async -> Locale? {
        await SpeechTranscriber.supportedLocale(equivalentTo: locale)
    }

    func status(for locale: Locale) async -> AssetStatus {
        guard let canonical = await canonicalLocale(for: locale) else { return .unsupported }
        let module = SpeechTranscriber(locale: canonical, preset: .progressiveTranscription)
        switch await AssetInventory.status(forModules: [module]) {
        case .unsupported: return .unsupported
        case .supported: return .notInstalled
        case .downloading: return .downloading
        case .installed: return .installed
        @unknown default: return .unsupported
        }
    }

    /// Downloads and installs the speech asset for a locale, reporting
    /// fractional progress as it goes. Returns immediately if the asset is
    /// already present.
    func install(locale: Locale, onProgress: @escaping @Sendable (Double) -> Void) async throws {
        guard let canonical = await canonicalLocale(for: locale) else { return }
        let module = SpeechTranscriber(locale: canonical, preset: .progressiveTranscription)
        guard let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) else {
            onProgress(1)
            return
        }

        let progress = request.progress
        let reporter = Task {
            while !Task.isCancelled {
                onProgress(progress.fractionCompleted)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        defer { reporter.cancel() }

        try await request.downloadAndInstall()
        onProgress(1)
    }

    /// Reserving keeps the system from reclaiming an installed asset. The
    /// cap is small (`maximumReservedLocales`, 5 on current hardware), so
    /// this is best-effort: failure to reserve doesn't break anything, the
    /// asset just isn't pinned.
    func reserveIfPossible(locale: Locale) async {
        guard let canonical = await canonicalLocale(for: locale) else { return }
        let reserved = await AssetInventory.reservedLocales
        guard !reserved.contains(where: { $0.identifier == canonical.identifier }) else { return }
        guard reserved.count < AssetInventory.maximumReservedLocales else { return }
        _ = try? await AssetInventory.reserve(locale: canonical)
    }
}

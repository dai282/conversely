import Foundation
import Speech
import AVFoundation
import Translation

/// Diagnostic for the "why is on-device STT unavailable, and can we fix it
/// programmatically?" question.
///
/// **The answer, for the record:** `SFSpeechRecognizer.supportsOnDeviceRecognition`
/// is just "is the Assistant (Siri/dictation) speech asset installed for
/// this locale" — the `No Assistant asset for language xx-XX` console line
/// is the system telling us exactly that. Spanish flipped from false to
/// true because adding its keyboard queued that asset download in the
/// background and it eventually finished. That is not something to fiddle
/// with in Settings and hope: iOS 26 exposes `AssetInventory`, which lets
/// the app query, download, and track progress for those assets directly.
///
/// Launch with `--language-scan` to report status for every candidate, or
/// `--language-scan --install=fr-FR` to actually download one.
@MainActor
final class LanguageScanRunner: ObservableObject {
    @Published private(set) var log: [String] = []

    private let pivot = Locale.Language(identifier: "en-US")

    private let candidates: [(name: String, locale: String)] = [
        ("English (US)", "en-US"),
        ("Vietnamese", "vi-VN"),
        ("Spanish (Spain)", "es-ES"),
        ("French", "fr-FR"),
        ("German", "de-DE"),
        ("Japanese", "ja-JP"),
        ("Russian", "ru-RU"),
        ("Chinese (Simplified)", "zh-Hans-CN"),
    ]

    func start() {
        Task { await run() }
    }

    private func append(_ message: String) {
        log.append(message)
        print("LANGUAGE_SCAN: \(message)")
    }

    private func run() async {
        await scan()

        // `--install=<locale>` proves the asset can be fetched from inside
        // the app, no Settings detour.
        if let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--install=") }) {
            let localeID = String(arg.dropFirst("--install=".count))
            await installSpeechAsset(localeID: localeID)
        }

        append("Scan complete")
    }

    private func scan() async {
        append("Scanning \(candidates.count) languages against en-US pivot...")

        if #available(iOS 26.0, *) {
            append("SpeechTranscriber.isAvailable: \(SpeechTranscriber.isAvailable)")
            let installed = await SpeechTranscriber.installedLocales
            append("SpeechTranscriber.installedLocales: \(installed.map(\.identifier).sorted())")
            let supported = await SpeechTranscriber.supportedLocales
            append("SpeechTranscriber.supportedLocales (\(supported.count)): \(supported.map(\.identifier).sorted())")
            append("AssetInventory.maximumReservedLocales: \(AssetInventory.maximumReservedLocales)")
            let reserved = await AssetInventory.reservedLocales
            append("AssetInventory.reservedLocales: \(reserved.map(\.identifier))")
        } else {
            append("iOS 26 Speech APIs unavailable on this OS")
        }

        for candidate in candidates {
            let locale = Locale(identifier: candidate.locale)

            // Legacy signal (what the app currently gates on).
            let legacySTT = SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition ?? false

            // iOS 26 signal — the one that's actionable.
            var assetStatus = "n/a"
            if #available(iOS 26.0, *) {
                if let canonical = await SpeechTranscriber.supportedLocale(equivalentTo: locale) {
                    let transcriber = SpeechTranscriber(locale: canonical, preset: .progressiveTranscription)
                    let status = await AssetInventory.status(forModules: [transcriber])
                    assetStatus = "\(status) (canonical: \(canonical.identifier))"
                } else {
                    assetStatus = "unsupported by SpeechTranscriber"
                }
            }

            let languageCode = locale.language.languageCode?.identifier ?? candidate.locale
            let voiceAvailable = AVSpeechSynthesisVoice.speechVoices().contains { $0.language.hasPrefix(languageCode) }

            let translationStatus: String
            if candidate.locale == "en-US" {
                translationStatus = "pivot"
            } else {
                switch await LanguageAvailability().status(from: pivot, to: .init(identifier: candidate.locale)) {
                case .installed: translationStatus = "installed"
                case .supported: translationStatus = "supported"
                case .unsupported: translationStatus = "unsupported"
                @unknown default: translationStatus = "unknown"
                }
            }

            append("\(candidate.name) (\(candidate.locale)): translation=\(translationStatus), legacySTT=\(legacySTT), asset=\(assetStatus), voice=\(voiceAvailable)")
        }
    }

    /// Downloads the on-device speech asset for a locale, reporting real
    /// progress — the programmatic equivalent of what adding a keyboard
    /// eventually triggered for Spanish.
    private func installSpeechAsset(localeID: String) async {
        guard #available(iOS 26.0, *) else {
            append("Install requires iOS 26+")
            return
        }

        append("--- Installing speech asset for \(localeID) ---")
        let locale = Locale(identifier: localeID)

        guard let canonical = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            append("\(localeID) is not supported by SpeechTranscriber; nothing to install")
            return
        }
        append("Canonical locale: \(canonical.identifier)")

        let transcriber = SpeechTranscriber(locale: canonical, preset: .progressiveTranscription)
        let before = await AssetInventory.status(forModules: [transcriber])
        append("Status before: \(before)")

        do {
            guard let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) else {
                append("No installation request needed — asset already present")
                return
            }

            // `progress` is a computed getter, so this probe checks both
            // readings: the object captured once up front (what
            // SpeechAssetService did, and which reported a frozen 0%) versus
            // re-reading `request.progress` on every tick. Logs unit counts
            // and object identity too, to tell "never updates" apart from
            // "updates a different object than the one we held".
            let captured = request.progress
            let reporter = Task {
                while !Task.isCancelled {
                    let live = request.progress
                    append(String(
                        format: "  captured=%.3f live=%.3f units=%lld/%lld indeterminate=%@ sameObject=%@",
                        captured.fractionCompleted,
                        live.fractionCompleted,
                        live.completedUnitCount,
                        live.totalUnitCount,
                        live.isIndeterminate ? "yes" : "no",
                        live === captured ? "yes" : "no"
                    ))
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }

            let start = Date()
            let installTask = Task { try await request.downloadAndInstall() }

            // `--cancel-after=<seconds>` aborts partway, which is how the
            // progress reading gets measured on a locale we don't want to
            // actually install — and doubles as a test of whether
            // `Progress.cancel()` really stops the download.
            if let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--cancel-after=") }),
               let seconds = Double(arg.dropFirst("--cancel-after=".count)) {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    append("  --- cancelling after \(seconds)s ---")
                    request.progress.cancel()
                    installTask.cancel()
                }
            }

            do {
                try await installTask.value
                append("downloadAndInstall() finished in \(String(format: "%.1f", Date().timeIntervalSince(start)))s")
            } catch {
                append("downloadAndInstall() threw after \(String(format: "%.1f", Date().timeIntervalSince(start)))s: \(error)")
            }
            reporter.cancel()
            append("progress after stop: \(request.progress.fractionCompleted), isCancelled=\(request.progress.isCancelled)")

            let after = await AssetInventory.status(forModules: [transcriber])
            append("Status after: \(after)")
            append("legacy supportsOnDeviceRecognition now: \(SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition ?? false)")

            let installed = await SpeechTranscriber.installedLocales
            append("installedLocales now: \(installed.map(\.identifier).sorted())")
        } catch {
            append("Install failed: \(error)")
        }
    }
}

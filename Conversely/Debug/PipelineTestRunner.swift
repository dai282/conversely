import Foundation
import Translation
import Speech

/// Drives the real STT/Translation/TTS services end-to-end for one hardcoded
/// pair (en-US <-> vi-VN), outside the production UI (DEVELOPMENT_PLAN.md,
/// Phase 1). Logs each step so latency and on-device availability can be
/// checked without wiring the real pipeline into Screen 1 yet — that's
/// Phase 2. Triggered by launching with the `--pipeline-test` argument (see
/// `ConverselyApp`).
///
/// Live microphone speech isn't exercised here — there's no way to feed a
/// human voice into the simulator programmatically. `translateAToB`/
/// `translateBToA` cover the parts of the pipeline that don't need one.
@MainActor
final class PipelineTestRunner: ObservableObject {
    @Published private(set) var log: [String] = []

    let translationService = TranslationService()
    private let speechRecognitionService = SpeechRecognitionService()
    private let speechSynthesisService = SpeechSynthesisService()
    private let audioCaptureService = AudioCaptureService()

    private let languageA = Locale.Language(identifier: "en-US")
    private let languageB = Locale.Language(identifier: "vi-VN")

    /// Candidates from the Language Management mockup, checked against
    /// en-US to see which pairs actually have full on-device support —
    /// PRD §10's "language coverage gaps" risk, worth validating with real
    /// API calls rather than assumption.
    private let coverageCandidates: [(name: String, locale: String)] = [
        ("Vietnamese", "vi-VN"),
        ("Spanish", "es-ES"),
        ("French", "fr-FR"),
        ("German", "de-DE"),
        ("Japanese", "ja-JP"),
    ]

    func start() {
        translationService.configure(languageA: languageA, languageB: languageB)
        Task { await runTests() }
    }

    private func append(_ message: String) {
        log.append(message)
        print("PIPELINE_TEST: \(message)")
    }

    private func runTests() async {
        append("Starting pipeline test (en-US <-> vi-VN)")

        append("--- Language coverage sweep (vs. en-US) ---")
        for candidate in coverageCandidates {
            let locale = Locale.Language(identifier: candidate.locale)
            let toStatus = await translationService.checkAvailability(from: languageA, to: locale)
            let fromStatus = await translationService.checkAvailability(from: locale, to: languageA)
            let sttSupported = await speechRecognitionService.supportsOnDeviceRecognition(locale: Locale(identifier: candidate.locale))
            append("\(candidate.name): translation en->\(candidate.locale)=\(toStatus), \(candidate.locale)->en=\(fromStatus); on-device STT=\(sttSupported)")
        }
        append("--- End coverage sweep ---")

        // Translation + TTS next: they don't need an interactive permission
        // dialog, so they can't get stuck waiting for a tap nobody can give
        // in an automated run.
        let statusAToB = await translationService.checkAvailability(from: languageA, to: languageB)
        append("Translation availability en->vi: \(statusAToB)")
        let statusBToA = await translationService.checkAvailability(from: languageB, to: languageA)
        append("Translation availability vi->en: \(statusBToA)")

        do {
            let sample = "Where is the nearest train station?"
            let start = Date()
            let translated = try await translationService.translateAToB(sample)
            let elapsed = Date().timeIntervalSince(start)
            append("Translated (en->vi) in \(String(format: "%.2f", elapsed))s: \"\(sample)\" -> \"\(translated)\"")

            let backStart = Date()
            let backTranslated = try await translationService.translateBToA(translated)
            let backElapsed = Date().timeIntervalSince(backStart)
            append("Translated (vi->en) in \(String(format: "%.2f", backElapsed))s: \"\(translated)\" -> \"\(backTranslated)\"")

            speechSynthesisService.speak(translated, locale: Locale(identifier: "vi-VN"))
            append("Requested TTS playback for translated text")
        } catch {
            append("Translation failed: \(error)")
        }

        // Exercised independently of translation succeeding — TTS doesn't
        // depend on the Translation framework at all.
        let bestEnglishVoice = SpeechSynthesisService.bestVoice(for: Locale(identifier: "en-US"))
        append("Best en-US voice: \(bestEnglishVoice?.name ?? "none found") (quality: \(bestEnglishVoice.map { "\($0.quality)" } ?? "n/a"))")
        speechSynthesisService.speak("Testing text to speech.", locale: Locale(identifier: "en-US"))
        append("Requested TTS playback (en-US, independent of translation result)")

        append("On-device STT supported (en-US): \(await speechRecognitionService.supportsOnDeviceRecognition(locale: Locale(identifier: "en-US")))")
        append("On-device STT supported (vi-VN): \(await speechRecognitionService.supportsOnDeviceRecognition(locale: Locale(identifier: "vi-VN")))")

        // Diagnostic: our Language model hardcodes one regional variant per
        // language (es-ES for Spanish). If the device's actual dictation
        // locale is a different Spanish variant (es-MX, es-US, generic
        // "es", etc.), supportsOnDeviceRecognition(locale: "es-ES") could
        // read false even with Spanish dictation genuinely enabled.
        let allSupportedLocales = SFSpeechRecognizer.supportedLocales()
        let spanishVariants = allSupportedLocales.filter { $0.identifier.hasPrefix("es") }
        append("All SFSpeechRecognizer.supportedLocales() matching 'es': \(spanishVariants.map(\.identifier).sorted())")
        for locale in spanishVariants.sorted(by: { $0.identifier < $1.identifier }) {
            let supported = SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition ?? false
            append("  \(locale.identifier): on-device=\(supported)")
        }

        // Both of these show an interactive system permission dialog on
        // first run. Race them against a timeout so a non-interactive run
        // (nobody available to tap Allow/Don't Allow) still finishes instead
        // of hanging forever; a real run on device/simulator will actually
        // resolve these once a person responds to the prompt.
        let sttAuthorized = await withTimeout(seconds: 5) { await self.speechRecognitionService.requestAuthorization() }
        append("Speech recognition authorized: \(sttAuthorized.map(String.init) ?? "pending (needs manual tap)")")

        let micGranted = await withTimeout(seconds: 5) { await self.audioCaptureService.requestMicrophonePermission() }
        append("Microphone permission granted: \(micGranted.map(String.init) ?? "pending (needs manual tap)")")

        append("Pipeline test complete")
    }

    /// Awaits `operation`, giving up (returning nil) after `seconds` instead
    /// of hanging — used only for the two calls above, which can otherwise
    /// block forever on a system permission dialog nothing here can dismiss.
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }
}

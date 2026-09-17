import Foundation
import Translation

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

        let sttAuthorized = await speechRecognitionService.requestAuthorization()
        append("Speech recognition authorized: \(sttAuthorized)")
        append("On-device STT supported (en-US): \(speechRecognitionService.supportsOnDeviceRecognition(locale: Locale(identifier: "en-US")))")
        append("On-device STT supported (vi-VN): \(speechRecognitionService.supportsOnDeviceRecognition(locale: Locale(identifier: "vi-VN")))")

        let micGranted = await audioCaptureService.requestMicrophonePermission()
        append("Microphone permission granted: \(micGranted)")

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

        append("Pipeline test complete")
    }
}

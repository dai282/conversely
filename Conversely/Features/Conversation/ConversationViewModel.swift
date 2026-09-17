import Foundation
import AVFoundation
import Translation

/// Drives Screen 1 with the real STT -> Translation -> TTS pipeline built in
/// Phase 1 (see DEVELOPMENT_PLAN.md, Phase 2). `tapMic` runs
/// Idle -> Listening -> Processing -> Result -> Idle against actual on-device
/// speech recognition and translation (PRD §5.1).
///
/// `TranslationService`'s `TranslationSession`s are hosted by `RootTabView`
/// (a session can only be vended via SwiftUI's `.translationTask`), so this
/// view model is handed a shared instance rather than owning one itself.
@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var languageA: Language
    @Published var languageB: Language
    @Published var turns: [ConversationTurn] = []
    @Published var activeSpeaker: Speaker?
    @Published var isProcessing = false
    @Published var liveTranscript: String = ""

    private let translationService: TranslationService
    private let speechRecognitionService = SpeechRecognitionService()
    private let audioCaptureService = AudioCaptureService()
    private let speechSynthesisService = SpeechSynthesisService()

    private var recognitionTask: Task<Void, Never>?
    private var didRequestPermissions = false

    init(languageA: Language = .english, languageB: Language = .vietnamese, translationService: TranslationService) {
        self.languageA = languageA
        self.languageB = languageB
        self.translationService = translationService
        translationService.configure(
            languageA: Self.localeLanguage(for: languageA),
            languageB: Self.localeLanguage(for: languageB)
        )
        requestPermissionsIfNeeded()
    }

    private func requestPermissionsIfNeeded() {
        guard !didRequestPermissions else { return }
        didRequestPermissions = true
        Task {
            _ = await speechRecognitionService.requestAuthorization()
            _ = await audioCaptureService.requestMicrophonePermission()
        }
    }

    func swapLanguages() {
        swap(&languageA, &languageB)
        translationService.configure(
            languageA: Self.localeLanguage(for: languageA),
            languageB: Self.localeLanguage(for: languageB)
        )
    }

    /// Mic tapped for a given side. Ignored for the inactive side while the
    /// other side is recording — only one speaker can record at a time.
    func tapMic(for speaker: Speaker) {
        if let activeSpeaker, activeSpeaker != speaker {
            return
        }

        if activeSpeaker == speaker {
            audioCaptureService.stopCapture()
        } else {
            startListening(for: speaker)
        }
    }

    /// Replays a bubble's translation — always in the *listener's* language,
    /// i.e. the language the other side speaks.
    func replay(_ turn: ConversationTurn) {
        let listenerLanguage = turn.speaker == .languageA ? languageB : languageA
        speechSynthesisService.speak(turn.translatedText, locale: Self.locale(for: listenerLanguage))
    }

    private func startListening(for speaker: Speaker) {
        recognitionTask?.cancel()
        activeSpeaker = speaker
        liveTranscript = ""
        isProcessing = false

        let sourceLanguage = speaker == .languageA ? languageA : languageB

        recognitionTask = Task { [weak self] in
            guard let self else { return }
            do {
                try self.audioCaptureService.activateAudioSession()
                let bufferStream = try self.audioCaptureService.startCapture()
                let recognitionStream = self.speechRecognitionService.recognize(
                    bufferStream: bufferStream,
                    locale: Self.locale(for: sourceLanguage)
                )

                var finalTranscript = ""
                for try await transcript in recognitionStream {
                    finalTranscript = transcript
                    self.liveTranscript = transcript
                }

                await self.finishTurn(for: speaker, transcript: finalTranscript)
            } catch {
                print("Recognition failed: \(error)")
                self.activeSpeaker = nil
                self.liveTranscript = ""
                self.isProcessing = false
            }
        }
    }

    private func finishTurn(for speaker: Speaker, transcript: String) async {
        guard !transcript.isEmpty else {
            activeSpeaker = nil
            liveTranscript = ""
            return
        }

        isProcessing = true

        do {
            let translated = speaker == .languageA
                ? try await translationService.translateAToB(transcript)
                : try await translationService.translateBToA(transcript)

            turns.append(
                ConversationTurn(
                    speaker: speaker,
                    timestamp: Date(),
                    originalText: transcript,
                    translatedText: translated
                )
            )

            let listenerLanguage = speaker == .languageA ? languageB : languageA
            speechSynthesisService.speak(translated, locale: Self.locale(for: listenerLanguage))
        } catch {
            print("Translation failed: \(error)")
        }

        isProcessing = false
        activeSpeaker = nil
        liveTranscript = ""
    }

    private static func locale(for language: Language) -> Locale {
        Locale(identifier: language.id)
    }

    private static func localeLanguage(for language: Language) -> Locale.Language {
        Locale.Language(identifier: language.id)
    }
}

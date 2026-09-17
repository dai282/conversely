import Foundation
import AVFoundation
import Translation
import Combine

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
    private let languageManagementViewModel: LanguageManagementViewModel
    private let speechRecognitionService = SpeechRecognitionService()
    private let audioCaptureService = AudioCaptureService()
    private let speechSynthesisService = SpeechSynthesisService()

    private var recognitionTask: Task<Void, Never>?
    private var didRequestPermissions = false
    private var languageManagementCancellable: AnyCancellable?

    /// Languages this screen's dropdowns can offer — only ones fully ready
    /// (Speech + Translation + Voice all present, per Language Management's
    /// compound status), so an unready language can never be selected in
    /// the first place rather than caught after the fact.
    var availableLanguages: [Language] {
        languageManagementViewModel.downloadedPacks.map(\.language)
    }

    init(
        languageA: Language = .english,
        languageB: Language = .vietnamese,
        translationService: TranslationService,
        languageManagementViewModel: LanguageManagementViewModel
    ) {
        self.languageA = languageA
        self.languageB = languageB
        self.translationService = translationService
        self.languageManagementViewModel = languageManagementViewModel
        translationService.configure(
            languageA: Self.localeLanguage(for: languageA),
            languageB: Self.localeLanguage(for: languageB)
        )
        requestPermissionsIfNeeded()

        // LanguageManagementViewModel is a separate ObservableObject; without
        // forwarding its changes, `availableLanguages` could go stale here
        // (e.g. right after a new download completes) until something else
        // happens to re-render this screen.
        languageManagementCancellable = languageManagementViewModel.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    private func requestPermissionsIfNeeded() {
        guard !didRequestPermissions else { return }
        didRequestPermissions = true
        Task {
            _ = await speechRecognitionService.requestAuthorization()
            _ = await audioCaptureService.requestMicrophonePermission()
        }
    }

    /// Manual reset of the visible feed — the same effect a relaunch has
    /// (turns are session-only per PRD §8.2), just without quitting the app.
    func clearConversation() {
        turns = []
    }

    func swapLanguages() {
        swap(&languageA, &languageB)
        translationService.configure(
            languageA: Self.localeLanguage(for: languageA),
            languageB: Self.localeLanguage(for: languageB)
        )
    }

    /// Picks a language for one side. Ignored if it matches the other
    /// side's current language — the picker UI already disables that
    /// option, this is just the backstop.
    func selectLanguage(_ language: Language, for side: Speaker) {
        switch side {
        case .languageA:
            guard language != languageB else { return }
            languageA = language
        case .languageB:
            guard language != languageA else { return }
            languageB = language
        }
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

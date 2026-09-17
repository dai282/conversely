import Foundation

/// Drives Screen 1 with canned/mock data so the UI can be built and reviewed
/// before the real STT -> Translation -> TTS pipeline lands (see DEVELOPMENT_PLAN.md, Phase 1).
/// `tapMic` simulates Idle -> Listening -> Processing -> Result -> Idle (PRD §5.1).
@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var languageA: Language
    @Published var languageB: Language
    @Published var turns: [ConversationTurn]
    @Published var activeSpeaker: Speaker?
    @Published var isProcessing = false
    @Published var liveTranscript: String = ""

    private var listeningTask: Task<Void, Never>?

    init(languageA: Language = .english, languageB: Language = .vietnamese) {
        self.languageA = languageA
        self.languageB = languageB
        self.turns = Self.seedTurns
        // Seeded to match the mockup: Language B is already mid-utterance on launch.
        self.activeSpeaker = .languageB
        self.liveTranscript = "Khoảng mười phút đi bộ..."
    }

    func swapLanguages() {
        swap(&languageA, &languageB)
    }

    /// Mic tapped for a given side. Ignored for the inactive side while the
    /// other side is recording — only one speaker can record at a time.
    func tapMic(for speaker: Speaker) {
        if let activeSpeaker, activeSpeaker != speaker {
            return
        }

        if activeSpeaker == speaker {
            finishTurn(for: speaker)
        } else {
            startListening(for: speaker)
        }
    }

    private func startListening(for speaker: Speaker) {
        listeningTask?.cancel()
        activeSpeaker = speaker
        liveTranscript = ""
        isProcessing = false

        let script = MockScript.next(for: speaker)
        listeningTask = Task { [weak self] in
            for character in script.original {
                guard let self, !Task.isCancelled else { return }
                self.liveTranscript.append(character)
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
            guard let self, !Task.isCancelled else { return }
            self.completeTurn(for: speaker, script: script)
        }
    }

    private func finishTurn(for speaker: Speaker) {
        listeningTask?.cancel()
        let script = MockScript.current(for: speaker, partial: liveTranscript)
        completeTurn(for: speaker, script: script)
    }

    private func completeTurn(for speaker: Speaker, script: MockScript.Line) {
        isProcessing = true
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard let self else { return }
            self.turns.append(
                ConversationTurn(
                    speaker: speaker,
                    timestamp: Date(),
                    originalText: script.original,
                    translatedText: script.translated
                )
            )
            self.isProcessing = false
            self.activeSpeaker = nil
            self.liveTranscript = ""
        }
    }

    /// Seed data mirroring Assets/duotranslate_conversation/screen.png exactly.
    private static let seedTurns: [ConversationTurn] = {
        let calendar = Calendar.current
        let base = calendar.date(bySettingHour: 10, minute: 42, second: 0, of: Date()) ?? Date()
        return [
            ConversationTurn(
                speaker: .languageA,
                timestamp: base,
                originalText: "Where is the nearest train station?",
                translatedText: "Ga xe lửa gần nhất ở đâu?"
            ),
            ConversationTurn(
                speaker: .languageB,
                timestamp: base,
                originalText: "Đi thẳng hai ngã tư nữa rồi rẽ phải.",
                translatedText: "Go straight for two more intersections, then turn right."
            ),
            ConversationTurn(
                speaker: .languageA,
                timestamp: Date(),
                originalText: "Thank you so much! Can I walk there?",
                translatedText: "Cảm ơn bạn rất nhiều! Tôi có thể đi bộ đến đó được không?"
            ),
        ]
    }()
}

/// Canned lines used only for the Phase 0 mock demo.
private enum MockScript {
    struct Line {
        let original: String
        let translated: String
    }

    static func next(for speaker: Speaker) -> Line {
        switch speaker {
        case .languageA:
            return Line(
                original: "How much does it cost?",
                translated: "Cái này giá bao nhiêu?"
            )
        case .languageB:
            return Line(
                original: "Khoảng mười phút đi bộ. Rất gần thôi.",
                translated: "It's about a ten minute walk. Very close."
            )
        }
    }

    static func current(for speaker: Speaker, partial: String) -> Line {
        guard !partial.isEmpty else { return next(for: speaker) }
        switch speaker {
        case .languageA:
            return Line(original: partial, translated: "Cái này giá bao nhiêu?")
        case .languageB:
            return Line(original: partial, translated: "It's about a ten minute walk. Very close.")
        }
    }
}

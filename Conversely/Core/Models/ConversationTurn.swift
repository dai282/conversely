import Foundation

/// Which side of the conversation spoke. Language A is always left-aligned,
/// Language B always right-aligned (PRD §5.1).
enum Speaker {
    case languageA
    case languageB
}

struct ConversationTurn: Identifiable {
    let id = UUID()
    let speaker: Speaker
    let timestamp: Date
    /// What was actually said, in the speaker's language (secondary/smaller style).
    let originalText: String
    /// The translation into the other language, auto-spoken aloud (primary/bold style).
    let translatedText: String
}

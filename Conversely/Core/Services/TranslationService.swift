import Translation
import Foundation

/// Wraps the `Translation` framework (PRD §7). A `TranslationSession` can
/// only be vended by SwiftUI's `.translationTask` modifier attached to a
/// live view — there is no plain initializer — so this service exposes
/// `configurationAToB` / `configurationBToA` for a hosting view to bind two
/// `.translationTask` modifiers to (one per direction, since a session is
/// unidirectional), and `attachAToB`/`attachBToA` for that view to hand back
/// the session once the framework vends it. Callers await `translateAToB`/
/// `translateBToA`, which suspend until a session is attached.
///
/// `RootTabView` hosts both `.translationTask` modifiers for the lifetime of
/// the app, so sessions stay attached across screens.
@MainActor
final class TranslationService: ObservableObject {
    @Published private(set) var configurationAToB: TranslationSession.Configuration?
    @Published private(set) var configurationBToA: TranslationSession.Configuration?

    private var sessionAToB: TranslationSession?
    private var sessionBToA: TranslationSession?
    private var waitersAToB: [CheckedContinuation<TranslationSession, Never>] = []
    private var waitersBToA: [CheckedContinuation<TranslationSession, Never>] = []

    /// Call whenever the conversation's language pair changes (including on
    /// swap) — `.translationTask` automatically re-vends sessions when its
    /// configuration's `source`/`target` change.
    func configure(languageA: Locale.Language, languageB: Locale.Language) {
        configurationAToB = .init(source: languageA, target: languageB)
        configurationBToA = .init(source: languageB, target: languageA)
    }

    func attachAToB(_ session: TranslationSession) {
        sessionAToB = session
        waitersAToB.forEach { $0.resume(returning: session) }
        waitersAToB.removeAll()
    }

    func attachBToA(_ session: TranslationSession) {
        sessionBToA = session
        waitersBToA.forEach { $0.resume(returning: session) }
        waitersBToA.removeAll()
    }

    func checkAvailability(from source: Locale.Language, to target: Locale.Language) async -> LanguageAvailability.Status {
        await LanguageAvailability().status(from: source, to: target)
    }

    func translateAToB(_ text: String) async throws -> String {
        let session: TranslationSession
        if let sessionAToB {
            session = sessionAToB
        } else {
            session = await withCheckedContinuation { waitersAToB.append($0) }
        }
        return try await session.translate(text).targetText
    }

    func translateBToA(_ text: String) async throws -> String {
        let session: TranslationSession
        if let sessionBToA {
            session = sessionBToA
        } else {
            session = await withCheckedContinuation { waitersBToA.append($0) }
        }
        return try await session.translate(text).targetText
    }
}

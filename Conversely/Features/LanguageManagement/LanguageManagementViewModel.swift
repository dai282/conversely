import Foundation

/// Drives Screen 2 with canned/mock pack statuses. Real per-component
/// availability checks and download/delete actions land in Phase 3
/// (see DEVELOPMENT_PLAN.md).
@MainActor
final class LanguageManagementViewModel: ObservableObject {
    @Published var packs: [LanguagePackStatus]
    @Published var displayLanguage: DisplayLanguage = .english

    init() {
        packs = [
            LanguagePackStatus(
                language: .english,
                speech: .downloaded,
                translation: .downloaded,
                voice: .downloaded,
                approximateSizeMB: 380
            ),
            LanguagePackStatus(
                language: .vietnamese,
                speech: .downloaded,
                translation: .downloaded,
                voice: .downloaded,
                approximateSizeMB: 410
            ),
            LanguagePackStatus(
                language: .japanese,
                speech: .downloaded,
                translation: .downloading(progress: 0.68),
                voice: .queued,
                approximateSizeMB: 490
            ),
            LanguagePackStatus(
                language: .spanish,
                speech: .notDownloaded,
                translation: .notDownloaded,
                voice: .notDownloaded,
                approximateSizeMB: 395
            ),
            LanguagePackStatus(
                language: .french,
                speech: .notDownloaded,
                translation: .notDownloaded,
                voice: .notDownloaded,
                approximateSizeMB: 420
            ),
            LanguagePackStatus(
                language: .german,
                speech: .notDownloaded,
                translation: .notDownloaded,
                voice: .notDownloaded,
                approximateSizeMB: 405
            ),
        ]
    }

    /// Fully downloaded languages.
    var downloadedPacks: [LanguagePackStatus] { packs.filter(\.isFullyReady) }
    /// Everything else — not yet downloaded or mid-download. An in-progress
    /// download stays here until it finishes, at which point it moves to
    /// Downloaded on its own; there's no separate "in progress" section.
    var availablePacks: [LanguagePackStatus] { packs.filter { !$0.isFullyReady } }

    func startDownload(for id: String) {
        guard let index = packs.firstIndex(where: { $0.id == id }) else { return }
        packs[index].speech = .downloading(progress: 0)
        packs[index].translation = .queued
        packs[index].voice = .queued
    }

    func delete(for id: String) {
        guard let index = packs.firstIndex(where: { $0.id == id }) else { return }
        packs[index].speech = .notDownloaded
        packs[index].translation = .notDownloaded
        packs[index].voice = .notDownloaded
    }

    func setDisplayLanguage(_ language: DisplayLanguage) {
        displayLanguage = language
    }
}

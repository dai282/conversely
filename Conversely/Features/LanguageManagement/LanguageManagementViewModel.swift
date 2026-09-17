import Foundation

/// Drives Screen 2 with canned/mock pack statuses. Real per-component
/// availability checks and download/delete actions land in Phase 3
/// (see DEVELOPMENT_PLAN.md).
@MainActor
final class LanguageManagementViewModel: ObservableObject {
    @Published var packs: [LanguagePackStatus]
    @Published var storageUsedDescription = "1.4 GB of 64 GB used"
    @Published var storageUsedFraction: Double = 1.4 / 64

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

    var readyPacks: [LanguagePackStatus] { packs.filter(\.isFullyReady) }
    var inProgressPacks: [LanguagePackStatus] { packs.filter(\.isInProgress) }
    var availablePacks: [LanguagePackStatus] {
        packs.filter { !$0.isFullyReady && !$0.isInProgress }
    }

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
}

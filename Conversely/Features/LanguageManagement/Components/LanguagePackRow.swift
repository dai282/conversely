import SwiftUI

struct LanguagePackRow: View {
    let pack: LanguagePackStatus
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(pack.language.flag)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pack.language.englishName)
                            .font(Theme.Typography.titleMd)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("\(pack.language.localizedName) • \(pack.approximateSizeMB) MB")
                            .font(Theme.Typography.bodySm)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                trailingControl
            }

            HStack(spacing: Theme.Spacing.sm) {
                componentChip("Speech", pack.speech)
                componentChip("Translation", pack.translation)
                componentChip("Voice", pack.voice)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Colors.outlineVariant, lineWidth: 1))
    }

    @ViewBuilder
    private var trailingControl: some View {
        if pack.isFullyReady {
            // Nothing to delete from this app — Translation packs, on-device
            // STT models, and TTS voices are all system-managed with no
            // public deletion API. See LanguageManagementViewModel's doc
            // comment.
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.primary)
        } else if pack.isInProgress {
            Image(systemName: "xmark")
                .foregroundStyle(Theme.Colors.textSecondary)
        } else {
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
    }

    private func componentChip(_ title: String, _ status: ComponentStatus) -> some View {
        HStack(spacing: 4) {
            icon(for: status)
            Text(chipLabel(title, status))
        }
        .font(Theme.Typography.labelSm)
        .foregroundStyle(Theme.Colors.textSecondary)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(Theme.Colors.surfaceContainerHigh, in: Capsule())
    }

    private func chipLabel(_ title: String, _ status: ComponentStatus) -> String {
        if case .downloading(let progress) = status {
            return "\(title) \(Int(progress * 100))%"
        }
        return title
    }

    @ViewBuilder
    private func icon(for status: ComponentStatus) -> some View {
        switch status {
        case .downloaded:
            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
        case .downloading:
            Image(systemName: "arrow.trianglehead.2.clockwise").font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.Colors.primary)
        case .queued:
            Image(systemName: "clock").font(.system(size: 9, weight: .bold))
        case .notDownloaded:
            EmptyView()
        case .unavailable:
            Image(systemName: "exclamationmark.triangle").font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.Colors.error)
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        LanguagePackRow(
            pack: LanguagePackStatus(language: .english, speech: .downloaded, translation: .downloaded, voice: .downloaded, approximateSizeMB: 380),
            onDownload: {}
        )
        LanguagePackRow(
            pack: LanguagePackStatus(language: .japanese, speech: .downloaded, translation: .downloading(progress: 0.68), voice: .queued, approximateSizeMB: 490),
            onDownload: {}
        )
        LanguagePackRow(
            pack: LanguagePackStatus(language: .spanish, speech: .notDownloaded, translation: .notDownloaded, voice: .notDownloaded, approximateSizeMB: 395),
            onDownload: {}
        )
    }
    .padding()
    .background(Theme.Colors.background)
}

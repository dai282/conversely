import SwiftUI

/// One language in the Languages list. Deliberately binary: ready, working on
/// it, or tap to download. The underlying Speech/Translation/Voice breakdown
/// isn't shown — the user can't act on any leg individually, and the Download
/// button fetches whichever ones are missing.
struct LanguagePackRow: View {
    let pack: LanguagePackStatus
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .center) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(pack.language.flag)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pack.language.englishName)
                            .font(Theme.Typography.titleMd)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(subtitle)
                            .font(Theme.Typography.bodySm)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                trailingControl
            }

            if let progress = pack.downloadProgress {
                ProgressView(value: progress)
                    .tint(Theme.Colors.primary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Colors.outlineVariant, lineWidth: 1))
    }

    private var subtitle: String {
        if let progress = pack.downloadProgress {
            return "Downloading… \(Int(progress * 100))%"
        }
        if pack.hasGap {
            return "\(pack.language.localizedName) • not supported on this device"
        }
        return "\(pack.language.localizedName) • \(pack.approximateSizeMB) MB"
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
            ProgressView()
                .controlSize(.small)
        } else if pack.hasGap {
            // No download would fix this one, so don't offer a button that
            // can't deliver.
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Theme.Colors.error)
        } else {
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.Colors.primary)
            }
            .accessibilityLabel("Download \(pack.language.englishName)")
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
            pack: LanguagePackStatus(language: .japanese, speech: .downloading(progress: 0.68), translation: .notDownloaded, voice: .downloaded, approximateSizeMB: 490),
            onDownload: {}
        )
        LanguagePackRow(
            pack: LanguagePackStatus(language: .spanish, speech: .notDownloaded, translation: .notDownloaded, voice: .downloaded, approximateSizeMB: 395),
            onDownload: {}
        )
    }
    .padding()
    .background(Theme.Colors.background)
}

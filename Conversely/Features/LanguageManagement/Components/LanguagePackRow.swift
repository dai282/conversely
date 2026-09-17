import SwiftUI

/// One language in the Languages list. Deliberately binary: ready, working on
/// it, or tap to download. The underlying Speech/Translation/Voice breakdown
/// isn't shown — the user can't act on any leg individually, and the Download
/// button fetches whichever ones are missing.
struct LanguagePackRow: View {
    let pack: LanguagePackStatus
    let onDownload: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: Theme.Spacing.sm) {
                Text(pack.language.flag)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: pack.language.name(in: locale))
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    subtitle
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            trailingControl
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Colors.outlineVariant, lineWidth: 1))
    }

    /// `Text` rather than `String` so these resolve against the environment's
    /// locale — a string built outside the view hierarchy would always come
    /// back in the system language, not the app's chosen one.
    private var subtitle: Text {
        if pack.isInProgress {
            // No percentage is possible for either downloadable leg, so the
            // spinner carries "something is happening" and this says what.
            return Text("Downloading…")
        }
        if pack.hasGap {
            return Text("\(pack.language.localizedName) • not supported on this device")
        }
        return Text("\(pack.language.localizedName) • \(pack.approximateSizeMB) MB")
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
                .tint(Theme.Colors.primary)
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
            .accessibilityLabel(Text("Download \(pack.language.name(in: locale))"))
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
            pack: LanguagePackStatus(language: .japanese, speech: .downloading, translation: .notDownloaded, voice: .downloaded, approximateSizeMB: 490),
            onDownload: {}
        )
        LanguagePackRow(
            pack: LanguagePackStatus(language: .chinese, speech: .downloaded, translation: .downloading, voice: .downloaded, approximateSizeMB: 460),
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

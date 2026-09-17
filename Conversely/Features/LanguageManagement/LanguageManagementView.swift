import SwiftUI
import Translation

struct LanguageManagementView: View {
    @ObservedObject var viewModel: LanguageManagementViewModel
    @EnvironmentObject private var localization: AppLocalization
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    section(title: "DOWNLOADED", packs: viewModel.downloadedPacks)
                    section(title: "AVAILABLE", packs: viewModel.availablePacks)

                    manageInSettingsBanner
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    displayLanguageSwitcher
                }
            }
            .translationTask(viewModel.pendingDownloadConfiguration) { session in
                await viewModel.handleDownloadSession(session)
            }
            .refreshable {
                await viewModel.refreshAllStatuses()
            }
        }
    }

    /// None of the three components (Speech, Translation, Voice) can be
    /// downloaded-or-deleted symmetrically from this app — Speech and Voice
    /// are entirely iOS-managed, and even downloaded Translation packs can
    /// only be deleted from Settings, not from here (see
    /// LanguageManagementViewModel's doc comment). This is informational,
    /// not a warning: there's no app URL scheme to jump straight to
    /// Settings → Apps → Translate → Languages (only to this app's own
    /// Settings page), so the copy spells out the rest of the path.
    private var manageInSettingsBanner: some View {
        Button(action: viewModel.openSystemSettings) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.Colors.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manage downloaded languages")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("To delete a downloaded language, open Settings → Apps → Translate → Languages.")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    /// UI display language switcher (PRD §6.1) — independent of the
    /// conversation languages managed by the rest of this screen.
    private var displayLanguageSwitcher: some View {
        Menu {
            ForEach(DisplayLanguage.supported) { language in
                Button {
                    localization.language = language
                } label: {
                    HStack {
                        Text(verbatim: "\(language.flag) \(language.name(in: locale))")
                        if language == localization.language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            // No background or border of our own: the toolbar already draws a
            // container around its items, and adding a circle inside it read
            // as a pill wrapped around a circle.
            Text(verbatim: localization.language.flag)
                .font(.system(size: 18))
        }
        .accessibilityLabel(Text("Change display language"))
    }

    @ViewBuilder
    private func section(title: LocalizedStringKey, packs: [LanguagePackStatus]) -> some View {
        if !packs.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.labelLg)
                    .foregroundStyle(Theme.Colors.primary)

                ForEach(packs) { pack in
                    LanguagePackRow(
                        pack: pack,
                        onDownload: { viewModel.startDownload(for: pack.id) }
                    )
                }
            }
        }
    }
}

#Preview {
    LanguageManagementView(viewModel: LanguageManagementViewModel())
        .preferredColorScheme(.dark)
}

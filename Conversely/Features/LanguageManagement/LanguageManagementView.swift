import SwiftUI
import Translation

struct LanguageManagementView: View {
    @ObservedObject var viewModel: LanguageManagementViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    section(title: "DOWNLOADED", count: viewModel.downloadedPacks.count, packs: viewModel.downloadedPacks)
                    section(title: "AVAILABLE", count: nil, packs: viewModel.availablePacks)

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
                    viewModel.setDisplayLanguage(language)
                } label: {
                    HStack {
                        Text("\(language.flag) \(language.englishName)")
                        if language == viewModel.displayLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(viewModel.displayLanguage.flag)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(Theme.Colors.surfaceContainerHigh, in: Circle())
                .overlay(Circle().stroke(Theme.Colors.outlineVariant, lineWidth: 1))
        }
        .accessibilityLabel("Change display language")
    }

    @ViewBuilder
    private func section(title: String, count: Int?, packs: [LanguagePackStatus]) -> some View {
        if !packs.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(title)
                        .font(Theme.Typography.labelLg)
                        .foregroundStyle(Theme.Colors.primary)
                    Spacer()
                    if let count {
                        Text("\(count) language\(count == 1 ? "" : "s")")
                            .font(Theme.Typography.bodySm)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

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

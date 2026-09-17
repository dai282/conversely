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

                    if viewModel.packs.contains(where: \.hasGap) {
                        settingsGapBanner
                    }
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

    /// Speech and Voice gaps can't be fixed from inside this app (PRD §5.2 —
    /// see LanguageManagementViewModel's doc comment for why); this is the
    /// honest alternative to a "download" button that wouldn't do anything.
    private var settingsGapBanner: some View {
        Button(action: viewModel.openSystemSettings) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Theme.Colors.error)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Some languages are missing Speech or Voice support")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("These are managed by iOS, not this app. Tap to open Settings.")
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

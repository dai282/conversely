import SwiftUI

struct LanguageManagementView: View {
    @ObservedObject var viewModel: LanguageManagementViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    storageCard

                    section(title: "READY OFFLINE", count: viewModel.readyPacks.count, packs: viewModel.readyPacks)
                    section(title: "IN PROGRESS", count: viewModel.inProgressPacks.count, packs: viewModel.inProgressPacks)
                    section(title: "ALL AVAILABLE LANGUAGES", count: nil, packs: viewModel.availablePacks)

                    voiceInfoBanner
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Languages")
        }
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "internaldrive")
                Text("Device storage")
                    .font(Theme.Typography.titleMd)
                Spacer()
                Text(viewModel.storageUsedDescription)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .foregroundStyle(Theme.Colors.textPrimary)

            ProgressView(value: viewModel.storageUsedFraction)
                .tint(Theme.Colors.primary)

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(Theme.Colors.primary)
                Text("Translate offline without an internet connection or cellular data")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
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
                        onDownload: { viewModel.startDownload(for: pack.id) },
                        onDelete: { viewModel.delete(for: pack.id) }
                    )
                }
            }
        }
    }

    private var voiceInfoBanner: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle")
                .foregroundStyle(Theme.Colors.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Enhanced voice synthesis")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Offline speech output uses on-device system voices. Additional natural voices can be downloaded in device Settings > Accessibility > Spoken Content.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

#Preview {
    LanguageManagementView(viewModel: LanguageManagementViewModel())
        .preferredColorScheme(.dark)
}

import SwiftUI

struct LanguageSelectorBar: View {
    let languageA: Language
    let languageB: Language
    let onSwap: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            label(for: languageA)

            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primary)
            }

            label(for: languageB)
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surfaceContainer, in: Capsule())
        .overlay(Capsule().stroke(Theme.Colors.outlineVariant, lineWidth: 1))
    }

    private func label(for language: Language) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(language.flag)
            Text(language.localizedName)
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LanguageSelectorBar(languageA: .english, languageB: .vietnamese, onSwap: {})
        .padding()
        .background(Theme.Colors.background)
}

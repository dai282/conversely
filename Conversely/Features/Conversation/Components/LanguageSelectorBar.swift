import SwiftUI

/// Each side is a dropdown (PRD §5.1: "tapping either opens a language
/// picker"), scoped to fully-downloaded languages only — an undownloaded
/// language can't be selected at all, not just flagged after the fact — and
/// excluding whichever language the *other* side currently has selected
/// (shown greyed out rather than hidden, so it's clear why it's unpickable).
struct LanguageSelectorBar: View {
    let languageA: Language
    let languageB: Language
    let availableLanguages: [Language]
    let onSelectA: (Language) -> Void
    let onSelectB: (Language) -> Void
    let onSwap: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            picker(current: languageA, excluding: languageB, onSelect: onSelectA)

            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primary)
            }

            picker(current: languageB, excluding: languageA, onSelect: onSelectB)
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surfaceContainer, in: Capsule())
        .overlay(Capsule().stroke(Theme.Colors.outlineVariant, lineWidth: 1))
    }

    private func picker(current: Language, excluding other: Language, onSelect: @escaping (Language) -> Void) -> some View {
        Menu {
            ForEach(availableLanguages) { language in
                Button {
                    onSelect(language)
                } label: {
                    HStack {
                        Text("\(language.flag) \(language.localizedName)")
                        if language == current {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(language == other)
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Text(current.flag)
                Text(current.localizedName)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    LanguageSelectorBar(
        languageA: .english,
        languageB: .vietnamese,
        availableLanguages: [.english, .vietnamese, .spanish],
        onSelectA: { _ in },
        onSelectB: { _ in },
        onSwap: {}
    )
    .padding()
    .background(Theme.Colors.background)
}

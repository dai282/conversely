import SwiftUI

/// Two large mic buttons, one per side. Only one can be active at a time —
/// the inactive side dims while the other is recording (PRD §5.1).
struct MicButtonRow: View {
    let languageA: Language
    let languageB: Language
    let activeSpeaker: Speaker?
    let onTap: (Speaker) -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            micButton(for: .languageA, language: languageA)
            micButton(for: .languageB, language: languageB)
        }
    }

    private func micButton(for speaker: Speaker, language: Language) -> some View {
        let isActive = activeSpeaker == speaker
        let isDimmed = activeSpeaker != nil && !isActive

        return Button {
            onTap(speaker)
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isActive ? Theme.Colors.onPrimary : Theme.Colors.primary)
                    .frame(width: 64, height: 64)
                    .background(isActive ? Theme.Colors.primary : Theme.Colors.surfaceContainerHigh, in: Circle())

                Text(language.englishName)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
            .opacity(isDimmed ? 0.4 : 1)
        }
        .disabled(isDimmed)
    }
}

#Preview {
    MicButtonRow(languageA: .english, languageB: .vietnamese, activeSpeaker: .languageB, onTap: { _ in })
        .padding()
        .background(Theme.Colors.background)
}

import SwiftUI

/// Two large mic buttons, one per side. Only one can be active at a time —
/// the inactive side dims while the other is recording (PRD §5.1).
struct MicButtonRow: View {
    let languageA: Language
    let languageB: Language
    let activeSpeaker: Speaker?
    let isProcessing: Bool
    let onTap: (Speaker) -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            micButton(for: .languageA, language: languageA)
            micButton(for: .languageB, language: languageB)
        }
    }

    private func micButton(for speaker: Speaker, language: Language) -> some View {
        let isActive = activeSpeaker == speaker
        return MicButton(
            language: language,
            isActive: isActive,
            isProcessing: isActive && isProcessing,
            isDimmed: activeSpeaker != nil && !isActive,
            onTap: { onTap(speaker) }
        )
    }
}

/// Split out from the row so each button owns the `@State` driving its own
/// pulse — a shared flag would animate both sides at once.
private struct MicButton: View {
    let language: Language
    let isActive: Bool
    let isProcessing: Bool
    let isDimmed: Bool
    let onTap: () -> Void

    @State private var isPulsing = false

    /// Recording and processing are visually distinct on purpose: a pulse
    /// that kept going after the mic stopped listening would suggest the app
    /// was still hearing you.
    private var isRecording: Bool { isActive && !isProcessing }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    if isRecording {
                        Circle()
                            .stroke(Theme.Colors.primary, lineWidth: 3)
                            .frame(width: 64, height: 64)
                            .scaleEffect(isPulsing ? 1.4 : 1)
                            .opacity(isPulsing ? 0 : 0.7)
                            .animation(
                                .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                            .onAppear { isPulsing = true }
                            .onDisappear { isPulsing = false }
                    }

                    Group {
                        if isProcessing {
                            ProgressView()
                                .tint(Theme.Colors.onPrimary)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(isActive ? Theme.Colors.onPrimary : Theme.Colors.primary)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .background(
                        isActive ? Theme.Colors.primary : Theme.Colors.surfaceContainerHigh,
                        in: Circle()
                    )
                }
                .scaleEffect(isRecording ? 1.06 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isActive)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isProcessing)

                Text(language.englishName)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
            .opacity(isDimmed ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.2), value: isDimmed)
        }
        .disabled(isDimmed)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if isProcessing { return "Processing \(language.englishName)" }
        if isActive { return "Listening in \(language.englishName). Tap to stop." }
        return "Speak \(language.englishName)"
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        MicButtonRow(languageA: .english, languageB: .vietnamese, activeSpeaker: nil, isProcessing: false, onTap: { _ in })
        MicButtonRow(languageA: .english, languageB: .vietnamese, activeSpeaker: .languageB, isProcessing: false, onTap: { _ in })
        MicButtonRow(languageA: .english, languageB: .vietnamese, activeSpeaker: .languageB, isProcessing: true, onTap: { _ in })
    }
    .padding()
    .background(Theme.Colors.background)
}

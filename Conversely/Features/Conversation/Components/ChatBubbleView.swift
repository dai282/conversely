import SwiftUI

/// Language A renders left-aligned in a neutral surface; Language B renders
/// right-aligned in a tinted surface. The replay button always sits on the
/// side facing the center of the screen (PRD §5.1).
struct ChatBubbleView: View {
    let turn: ConversationTurn
    let languageA: Language
    let languageB: Language
    let onReplay: () -> Void

    private var isLanguageA: Bool { turn.speaker == .languageA }
    private var speakerLanguage: Language { isLanguageA ? languageA : languageB }

    var body: some View {
        VStack(alignment: isLanguageA ? .leading : .trailing, spacing: Theme.Spacing.xs) {
            Text("\(speakerLanguage.englishName) • \(timeLabel)")
                .font(Theme.Typography.labelMd)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                if isLanguageA {
                    bubble
                    replayButton
                } else {
                    replayButton
                    bubble
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isLanguageA ? .leading : .trailing)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(turn.translatedText)
                .font(Theme.Typography.headlineSm)
                .foregroundStyle(Theme.Colors.textPrimary)

            Divider().overlay(Theme.Colors.outlineVariant)

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                Text(turn.originalText)
                    .font(Theme.Typography.bodyMd)
            }
            .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: 280, alignment: .leading)
        .background(bubbleColor, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }

    private var replayButton: some View {
        Button(action: onReplay) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(Theme.Colors.surfaceContainerHigh, in: Circle())
        }
    }

    private var bubbleColor: Color {
        isLanguageA ? Theme.Colors.surfaceContainer : Theme.Colors.secondaryContainer.opacity(0.35)
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: turn.timestamp)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        ChatBubbleView(
            turn: ConversationTurn(
                speaker: .languageA,
                timestamp: Date(),
                originalText: "Where is the nearest train station?",
                translatedText: "Ga xe lửa gần nhất ở đâu?"
            ),
            languageA: .english,
            languageB: .vietnamese,
            onReplay: {}
        )
        ChatBubbleView(
            turn: ConversationTurn(
                speaker: .languageB,
                timestamp: Date(),
                originalText: "Đi thẳng hai ngã tư nữa rồi rẽ phải.",
                translatedText: "Go straight for two more intersections, then turn right."
            ),
            languageA: .english,
            languageB: .vietnamese,
            onReplay: {}
        )
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Theme.Colors.background)
}

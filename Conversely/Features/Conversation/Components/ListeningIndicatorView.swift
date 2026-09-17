import SwiftUI

/// Shown above the mic buttons while a side is actively recording, with the
/// live partial transcript streaming in (PRD §5.1 "Listening" state).
struct ListeningIndicatorView: View {
    let transcript: String
    let isProcessing: Bool

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "arrow.trianglehead.2.clockwise")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.onPrimary)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.primary, in: Circle())
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    isProcessing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                    value: isAnimating
                )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(isProcessing ? "PROCESSING…" : "LISTENING…")
                    .font(Theme.Typography.labelLg)
                    .foregroundStyle(Theme.Colors.primary)
                Text(transcript.isEmpty ? "…" : "\u{201C}\(transcript)\u{201D}")
                    .font(Theme.Typography.bodyLg)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.secondaryContainer.opacity(0.35), in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .onAppear { isAnimating = true }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        ListeningIndicatorView(transcript: "Khoảng mười phút đi bộ...", isProcessing: false)
        ListeningIndicatorView(transcript: "Khoảng mười phút đi bộ...", isProcessing: true)
    }
    .padding()
    .background(Theme.Colors.background)
}

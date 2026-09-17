import SwiftUI

struct ConversationView: View {
    @ObservedObject var viewModel: ConversationViewModel

    var body: some View {
        VStack(spacing: 0) {
            LanguageSelectorBar(
                languageA: viewModel.languageA,
                languageB: viewModel.languageB,
                onSwap: viewModel.swapLanguages
            )
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.lg) {
                        if viewModel.turns.isEmpty && viewModel.activeSpeaker == nil {
                            emptyState
                        }

                        ForEach(viewModel.turns) { turn in
                            ChatBubbleView(
                                turn: turn,
                                languageA: viewModel.languageA,
                                languageB: viewModel.languageB,
                                onReplay: { viewModel.replay(turn) }
                            )
                            .id(turn.id)
                        }

                        if viewModel.activeSpeaker != nil {
                            ListeningIndicatorView(
                                transcript: viewModel.liveTranscript,
                                isProcessing: viewModel.isProcessing
                            )
                            .id("listening")
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
                .onChange(of: viewModel.turns.count) {
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.activeSpeaker) {
                    scrollToBottom(proxy)
                }
                .onAppear {
                    scrollToBottom(proxy)
                }
            }

            MicButtonRow(
                languageA: viewModel.languageA,
                languageB: viewModel.languageB,
                activeSpeaker: viewModel.activeSpeaker,
                onTap: viewModel.tapMic
            )
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.activeSpeaker != nil {
                proxy.scrollTo("listening", anchor: .bottom)
            } else {
                proxy.scrollTo(viewModel.turns.last?.id, anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        Text("Choose your two languages, then tap a mic to start talking.")
            .font(Theme.Typography.bodyLg)
            .foregroundStyle(Theme.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.top, Theme.Spacing.xxl)
    }
}

#Preview {
    ConversationView(viewModel: ConversationViewModel(translationService: TranslationService()))
        .preferredColorScheme(.dark)
}

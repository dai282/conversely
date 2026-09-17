import SwiftUI
import Translation

/// Two screens total, per PRD: Converse (default) and Languages.
///
/// Hosts the two `.translationTask` modifiers `TranslationService` needs —
/// a `TranslationSession` can only be vended by SwiftUI through that
/// modifier, so it's attached here (rather than inside `ConversationView`)
/// to stay alive for the app's lifetime rather than being torn down each
/// time the Converse tab is unmounted.
struct RootTabView: View {
    @StateObject private var translationService: TranslationService
    @StateObject private var conversationViewModel: ConversationViewModel
    @StateObject private var languageManagementViewModel: LanguageManagementViewModel
    @StateObject private var localization = AppLocalization()

    init() {
        let translationService = TranslationService()
        let languageManagementViewModel = LanguageManagementViewModel()
        _translationService = StateObject(wrappedValue: translationService)
        _languageManagementViewModel = StateObject(wrappedValue: languageManagementViewModel)
        _conversationViewModel = StateObject(
            wrappedValue: ConversationViewModel(
                translationService: translationService,
                languageManagementViewModel: languageManagementViewModel
            )
        )
    }

    var body: some View {
        TabView {
            ConversationView(viewModel: conversationViewModel)
                .tabItem {
                    Label("Converse", systemImage: "character.bubble")
                }
                .tag(0)

            LanguageManagementView(viewModel: languageManagementViewModel)
                .tabItem {
                    Label("Languages", systemImage: "arrow.down.circle")
                }
                .tag(1)
        }
        .tint(Theme.Colors.primary)
        .environmentObject(localization)
        // What actually swaps the UI language: `Text` resolves String Catalog
        // keys against this, so publishing it here re-renders every label.
        .environment(\.locale, localization.language.locale)
        .translationTask(translationService.configurationAToB) { session in
            translationService.attachAToB(session)
        }
        .translationTask(translationService.configurationBToA) { session in
            translationService.attachBToA(session)
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.Colors.surfaceContainerLowest)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .preferredColorScheme(.dark)
}

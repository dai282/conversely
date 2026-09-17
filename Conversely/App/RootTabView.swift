import SwiftUI

/// Two screens total, per PRD: Converse (default) and Languages.
struct RootTabView: View {
    var body: some View {
        TabView {
            ConversationView(viewModel: ConversationViewModel())
                .tabItem {
                    Label("Converse", systemImage: "character.bubble")
                }

            LanguageManagementView(viewModel: LanguageManagementViewModel())
                .tabItem {
                    Label("Languages", systemImage: "arrow.down.circle")
                }
        }
        .tint(Theme.Colors.primary)
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

import SwiftUI

@main
struct ConverselyApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                if CommandLine.arguments.contains("--language-scan") {
                    LanguageScanHostView()
                } else if CommandLine.arguments.contains("--pipeline-test") {
                    PipelineTestHostView()
                } else {
                    RootTabView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

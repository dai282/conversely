import SwiftUI
import Translation

/// Hosts the two `.translationTask` modifiers `TranslationService` needs
/// (one per direction) and kicks off `PipelineTestRunner`. Only reachable by
/// launching with `--pipeline-test` — never part of the two-screen MVP nav.
struct PipelineTestHostView: View {
    @StateObject private var runner = PipelineTestRunner()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(runner.log.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.ignoresSafeArea())
        .translationTask(runner.translationService.configurationAToB) { session in
            runner.translationService.attachAToB(session)
        }
        .translationTask(runner.translationService.configurationBToA) { session in
            runner.translationService.attachBToA(session)
        }
        .task {
            runner.start()
        }
    }
}

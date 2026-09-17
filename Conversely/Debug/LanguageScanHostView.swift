import SwiftUI

/// Hosts `LanguageScanRunner`. No `.translationTask` needed here — unlike
/// `PipelineTestHostView`, this only calls the session-free
/// `LanguageAvailability.status(from:to:)`, never `translate()`/
/// `prepareTranslation()`. Only reachable via `--language-scan`.
struct LanguageScanHostView: View {
    @StateObject private var runner = LanguageScanRunner()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
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
        .task {
            runner.start()
        }
    }
}

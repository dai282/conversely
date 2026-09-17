import Speech
import AVFoundation
import CoreMedia

/// On-device transcription (PRD §7). Deliberately hybrid, because the two
/// Apple speech APIs cover different languages and neither alone is enough:
///
/// - **`SpeechTranscriber` (iOS 26)** — used when it supports the locale.
///   Its assets are installable from inside the app (`SpeechAssetService`),
///   which is the only way to make a new language work without sending the
///   user into Settings. Covers ~30 locales.
/// - **`SFSpeechRecognizer` (legacy)** — fallback. Covers more languages
///   (Vietnamese, Thai, Russian…) but its on-device assets can only be
///   installed by the system via Settings, so a language that isn't already
///   present can't be fixed from here.
///
/// Recognition is always on-device; the MVP never falls back to server-side.
final class SpeechRecognitionService {
    enum RecognitionError: Error {
        case recognizerUnavailable
        case onDeviceUnsupported
    }

    private var legacyTask: SFSpeechRecognitionTask?

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// True if *either* engine can transcribe this locale on-device right
    /// now. `SpeechAssetService` reports whether a currently-false locale
    /// can be made true by downloading.
    func supportsOnDeviceRecognition(locale: Locale) async -> Bool {
        if await Self.legacyOnDeviceSupport(for: locale) {
            return true
        }
        if #available(iOS 26.0, *) {
            return await SpeechAssetService().status(for: locale) == .installed
        }
        return false
    }

    /// Whether the legacy *Assistant* asset for this locale is on disk.
    ///
    /// Both `SFSpeechRecognizer.init` and `supportsOnDeviceRecognition` block
    /// on a synchronous XPC round-trip. Calling them straight from an async
    /// context stalls a cooperative thread — and the main one, from a
    /// `@MainActor` view model refreshing every language in a loop. That's
    /// what the runtime's "unsafeForcedSync called from Swift Concurrent
    /// context" diagnostic is pointing at. Hopping onto a plain GCD queue
    /// keeps the blocking work off the concurrency pool entirely.
    static func legacyOnDeviceSupport(for locale: Locale) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let supported = SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition == true
                continuation.resume(returning: supported)
            }
        }
    }

    /// Streams transcripts as buffers arrive; finishes when the recognizer
    /// reports a final result, the buffer stream ends, or an error occurs.
    func recognize(bufferStream: AsyncStream<AVAudioPCMBuffer>, locale: Locale) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                if #available(iOS 26.0, *),
                   await SpeechAssetService().status(for: locale) == .installed,
                   let canonical = await SpeechAssetService().canonicalLocale(for: locale) {
                    await self.runSpeechAnalyzer(
                        bufferStream: bufferStream,
                        canonical: canonical,
                        continuation: continuation
                    )
                } else {
                    self.runLegacyRecognizer(
                        bufferStream: bufferStream,
                        locale: locale,
                        continuation: continuation
                    )
                }
            }
            continuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.legacyTask?.cancel()
                self?.legacyTask = nil
            }
        }
    }

    func stop() {
        legacyTask?.finish()
    }

    // MARK: - iOS 26 SpeechTranscriber path

    @available(iOS 26.0, *)
    private func runSpeechAnalyzer(
        bufferStream: AsyncStream<AVAudioPCMBuffer>,
        canonical: Locale,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        do {
            let transcriber = SpeechTranscriber(locale: canonical, preset: .progressiveTranscription)
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            let targetFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

            let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()

            try await analyzer.start(inputSequence: inputStream)

            // Feeds mic audio in, converting to whatever format the
            // transcriber wants, then finalizes so the results stream ends.
            let feedTask = Task {
                var converter: AVAudioConverter?
                for await buffer in bufferStream {
                    guard let targetFormat, buffer.format != targetFormat else {
                        inputContinuation.yield(AnalyzerInput(buffer: buffer))
                        continue
                    }
                    if converter == nil {
                        converter = AVAudioConverter(from: buffer.format, to: targetFormat)
                    }
                    if let converted = Self.convert(buffer, using: converter, to: targetFormat) {
                        inputContinuation.yield(AnalyzerInput(buffer: converted))
                    }
                }
                inputContinuation.finish()
                try? await analyzer.finalizeAndFinishThroughEndOfInput()
            }

            // Results arrive per time range; a volatile range is later
            // replaced by its finalized version with the same start time,
            // so key on start time and re-emit the joined transcript.
            var segments: [(start: CMTime, text: String)] = []
            for try await result in transcriber.results {
                let text = String(result.text.characters)
                let start = result.range.start
                if let index = segments.firstIndex(where: { $0.start == start }) {
                    segments[index].text = text
                } else {
                    segments.append((start, text))
                    segments.sort { CMTimeCompare($0.start, $1.start) < 0 }
                }
                let joined = segments.map(\.text).joined()
                continuation.yield(joined.trimmingCharacters(in: .whitespaces))
            }

            feedTask.cancel()
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }

    @available(iOS 26.0, *)
    private static func convert(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter?,
        to format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard let converter else { return nil }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }

        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil && output.frameLength > 0 ? output : nil
    }

    // MARK: - Legacy SFSpeechRecognizer path

    private func runLegacyRecognizer(
        bufferStream: AsyncStream<AVAudioPCMBuffer>,
        locale: Locale,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            continuation.finish(throwing: RecognitionError.recognizerUnavailable)
            return
        }
        guard recognizer.supportsOnDeviceRecognition else {
            continuation.finish(throwing: RecognitionError.onDeviceUnsupported)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true

        legacyTask = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                continuation.yield(result.bestTranscription.formattedString)
                if result.isFinal {
                    continuation.finish()
                }
            }
            if let error {
                continuation.finish(throwing: error)
            }
        }

        Task {
            for await buffer in bufferStream {
                request.append(buffer)
            }
            request.endAudio()
        }
    }
}

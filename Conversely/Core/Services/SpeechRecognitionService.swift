import Speech
import AVFoundation

/// Wraps `SFSpeechRecognizer` for on-device transcription (PRD §7). Feeds
/// PCM buffers from `AudioCaptureService` into a
/// `SFSpeechAudioBufferRecognitionRequest` and streams back partial/final
/// transcripts. Recognition is forced on-device — the MVP never falls back
/// to server-side recognition.
final class SpeechRecognitionService {
    enum RecognitionError: Error {
        case recognizerUnavailable
        case onDeviceUnsupported
    }

    private var task: SFSpeechRecognitionTask?

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func supportsOnDeviceRecognition(locale: Locale) -> Bool {
        SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition ?? false
    }

    /// Streams transcripts as buffers arrive; the stream finishes when the
    /// recognizer reports a final result, the buffer stream ends, or an
    /// error occurs.
    func recognize(bufferStream: AsyncStream<AVAudioPCMBuffer>, locale: Locale) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
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

            task = recognizer.recognitionTask(with: request) { result, error in
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

            let feedTask = Task {
                for await buffer in bufferStream {
                    request.append(buffer)
                }
                request.endAudio()
            }

            continuation.onTermination = { [weak self] _ in
                feedTask.cancel()
                self?.task?.cancel()
                self?.task = nil
            }
        }
    }

    func stop() {
        task?.finish()
    }
}

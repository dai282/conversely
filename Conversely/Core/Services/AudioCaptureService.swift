import AVFoundation

/// Wraps `AVAudioEngine` to stream microphone buffers for on-device speech
/// recognition (PRD §7). Owns audio session configuration and engine
/// lifecycle; `SpeechRecognitionService` consumes the buffer stream.
final class AudioCaptureService {
    enum CaptureError: Error {
        case engineStartFailed(Error)
    }

    private let engine = AVAudioEngine()
    private var continuation: AsyncStream<AVAudioPCMBuffer>.Continuation?

    var isRunning: Bool { engine.isRunning }

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Configures the shared audio session for simultaneous record + playback
    /// (mic capture while also being able to speak translations aloud).
    func activateAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Starts capturing and returns a stream of PCM buffers at the input
    /// node's native format. Call `stopCapture()` to end the stream (letting
    /// a consumer like `SpeechRecognitionService` see the end and finalize
    /// its last result) and tear down the tap/engine.
    func startCapture() throws -> AsyncStream<AVAudioPCMBuffer> {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let stream = AsyncStream<AVAudioPCMBuffer> { continuation in
            self.continuation = continuation
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                continuation.yield(buffer)
            }
            // Covers teardown when the *consumer* stops iterating (e.g. its
            // Task is cancelled) as well as the explicit stopCapture() path
            // below, which finishes the continuation itself.
            continuation.onTermination = { [weak self] _ in
                self?.teardownEngine()
            }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            throw CaptureError.engineStartFailed(error)
        }
        return stream
    }

    /// Producer-side stop: finishes the buffer stream so whoever is
    /// consuming it (e.g. the recognition request's feed loop) sees the end
    /// and can call `endAudio()` to get a final transcript.
    func stopCapture() {
        continuation?.finish()
        continuation = nil
    }

    private func teardownEngine() {
        guard engine.isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}

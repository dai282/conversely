import AVFoundation

/// Wraps `AVAudioEngine` to stream microphone buffers for on-device speech
/// recognition (PRD §7). Owns audio session configuration and engine
/// lifecycle; `SpeechRecognitionService` consumes the buffer stream.
final class AudioCaptureService {
    enum CaptureError: Error {
        case engineStartFailed(Error)
    }

    private let engine = AVAudioEngine()

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
    /// node's native format. Call `stopCapture()` (or cancel consumption of
    /// the stream) to tear down the tap and stop the engine.
    func startCapture() throws -> AsyncStream<AVAudioPCMBuffer> {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let stream = AsyncStream<AVAudioPCMBuffer> { continuation in
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                continuation.yield(buffer)
            }
            continuation.onTermination = { [weak self] _ in
                self?.stopCapture()
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

    func stopCapture() {
        guard engine.isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}

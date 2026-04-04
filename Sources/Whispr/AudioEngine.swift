import AVFoundation
import Accelerate

final class AudioEngine {
    private let engine = AVAudioEngine()
    private var audioSamples: [Float] = []
    private let sampleRate: Double = 16000
    private let lock = NSLock()

    var onAudioLevel: (([CGFloat]) -> Void)?
    var onChunkReady: (([Float]) -> Void)?

    private var chunkTimer: Timer?
    private let chunkInterval: TimeInterval = 1.5
    private var levelHistory: [CGFloat] = Array(repeating: 0, count: 30)

    func start() throws {
        audioSamples = []

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioEngineError.converterFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * self.sampleRate / inputFormat.sampleRate
            )
            guard frameCount > 0,
                  let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else { return }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard status != .error, let channelData = convertedBuffer.floatChannelData else { return }
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(convertedBuffer.frameLength)))

            // Calculate RMS for waveform
            var rms: Float = 0
            vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
            let level = CGFloat(min(rms * 12, 1.0))

            self.lock.lock()
            self.audioSamples.append(contentsOf: samples)
            self.levelHistory.removeFirst()
            self.levelHistory.append(level)
            let currentLevels = self.levelHistory
            self.lock.unlock()

            DispatchQueue.main.async {
                self.onAudioLevel?(currentLevels)
            }
        }

        engine.prepare()
        try engine.start()

        // Periodic chunk sending for streaming transcription
        DispatchQueue.main.async {
            self.chunkTimer = Timer.scheduledTimer(withTimeInterval: self.chunkInterval, repeats: true) { [weak self] _ in
                self?.flushChunk()
            }
        }
    }

    func stop() -> [Float] {
        chunkTimer?.invalidate()
        chunkTimer = nil
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        lock.lock()
        let finalSamples = audioSamples
        audioSamples = []
        lock.unlock()

        return finalSamples
    }

    private func flushChunk() {
        lock.lock()
        guard !audioSamples.isEmpty else {
            lock.unlock()
            return
        }
        let chunk = audioSamples
        lock.unlock()

        onChunkReady?(chunk)
    }

    enum AudioEngineError: Error {
        case converterFailed
    }
}

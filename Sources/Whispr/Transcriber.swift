import WhisperKit
import Foundation

final class Transcriber {
    private var whisperKit: WhisperKit?
    private let appState = AppState.shared

    func loadModel() async {
        await MainActor.run {
            appState.isModelLoading = true
            appState.modelLoadProgress = "Downloading model..."
        }

        let modelName = Settings.shared.modelName
        NSLog("[Whispr] Loading model: %@", modelName)

        do {
            let config = WhisperKitConfig(model: modelName)
            let kit = try await WhisperKit(config)
            whisperKit = kit
            await MainActor.run {
                appState.isModelLoaded = true
                appState.isModelLoading = false
                appState.modelLoadProgress = ""
                appState.lastError = nil
            }
            NSLog("[Whispr] Model loaded successfully")
        } catch {
            await MainActor.run {
                appState.isModelLoading = false
                appState.lastError = "Failed to load model: \(error.localizedDescription)\nError: \(error)"
            }
            NSLog("[Whispr] Model load error: %@", "\(error)")
        }
    }

    func transcribe(samples: [Float]) async -> String {
        guard let kit = whisperKit else {
            NSLog("[Whispr] Transcribe called but whisperKit is nil")
            return ""
        }
        guard !samples.isEmpty else {
            NSLog("[Whispr] Transcribe called with empty samples")
            return ""
        }

        NSLog("[Whispr] Transcribing %d samples (%.1fs of audio)", samples.count, Double(samples.count) / 16000.0)

        do {
            let options = DecodingOptions(
                chunkingStrategy: .none
            )
            let results = try await kit.transcribe(audioArray: samples, decodeOptions: options)
            let text = results.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: " ")
            NSLog("[Whispr] Transcription result: '%@'", text)
            return text
        } catch {
            NSLog("[Whispr] Transcription error: %@", "\(error)")
            return ""
        }
    }
}

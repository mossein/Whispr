import WhisperKit
import Foundation

final class Transcriber {
    private var whisperKit: WhisperKit?
    private let appState = AppState.shared

    func loadModel() async {
        await MainActor.run {
            appState.isModelLoading = true
            appState.modelLoadProgress = "Downloading model (first launch only)..."
        }

        do {
            let config = WhisperKitConfig(model: "large-v3")
            let kit = try await WhisperKit(config)
            whisperKit = kit
            await MainActor.run {
                appState.isModelLoaded = true
                appState.isModelLoading = false
                appState.modelLoadProgress = ""
            }
            print("[Whispr] Model loaded successfully")
        } catch {
            await MainActor.run {
                appState.isModelLoading = false
                appState.lastError = "Failed to load model: \(error.localizedDescription)"
            }
            print("[Whispr] Model load error: \(error)")
        }
    }

    func transcribe(samples: [Float]) async -> String {
        guard let kit = whisperKit else { return "" }
        guard !samples.isEmpty else { return "" }

        do {
            let results = try await kit.transcribe(audioArray: samples)
            let text = results.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: " ")
            return text
        } catch {
            print("[Whispr] Transcription error: \(error)")
            return ""
        }
    }
}

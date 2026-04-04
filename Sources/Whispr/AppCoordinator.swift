import Foundation
import AppKit

final class AppCoordinator {
    static let shared = AppCoordinator()

    private let keyMonitor = KeyMonitor()
    private let audioEngine = AudioEngine()
    private let transcriber = Transcriber()
    private let popup = PopupPanel()
    private let appState = AppState.shared

    private init() {
        setup()
    }

    private func setup() {
        // Load model on launch
        Task {
            await transcriber.loadModel()
        }

        // Wire key monitor
        keyMonitor.onRightCommandDown = { [weak self] in
            self?.startRecording()
        }
        keyMonitor.onRightCommandUp = { [weak self] in
            self?.stopRecording()
        }

        // Wire audio levels to app state
        audioEngine.onAudioLevel = { [weak self] levels in
            self?.appState.audioLevels = levels
        }

        // Start listening for the hotkey
        keyMonitor.start()
    }

    private func startRecording() {
        guard appState.isModelLoaded, !appState.isRecording else { return }
        appState.isRecording = true
        appState.transcribedText = ""

        popup.show()

        do {
            try audioEngine.start()
        } catch {
            print("[Whispr] Failed to start audio: \(error)")
            appState.isRecording = false
            popup.dismiss()
        }
    }

    private func stopRecording() {
        guard appState.isRecording else { return }
        appState.isRecording = false

        let samples = audioEngine.stop()
        popup.dismiss()

        // Reset levels
        appState.audioLevels = Array(repeating: 0, count: 30)

        guard !samples.isEmpty else { return }

        // Transcribe the full recording and paste
        Task {
            let text = await transcriber.transcribe(samples: samples)
            guard !text.isEmpty else { return }
            await MainActor.run {
                PasteService.paste(text: text)
            }
        }
    }
}

import Foundation
import AppKit

final class AppCoordinator {
    static let shared = AppCoordinator()

    let keyMonitor = KeyMonitor()
    private let audioEngine = AudioEngine()
    let transcriber = Transcriber()
    private let popup = PopupPanel()
    private let appState = AppState.shared
    private let onboardingWindow = OnboardingWindow()

    private init() {
        setup()
    }

    private func setup() {
        // Wire key monitor
        keyMonitor.onRightCommandDown = { [weak self] in
            self?.startRecording()
        }
        keyMonitor.onRightCommandUp = { [weak self] in
            self?.stopRecording()
        }

        // Wire audio levels to app state
        audioEngine.onAudioLevel = { [weak self] (levels: [CGFloat]) in
            self?.appState.audioLevels = levels
        }

        // Update key code from settings and start monitor
        keyMonitor.triggerKeyCode = Int64(Settings.shared.triggerKeyCode)
        keyMonitor.start()

        // Always load model on launch
        Task {
            await transcriber.loadModel()
        }

        // Re-register monitors after sleep/wake
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            NSLog("[Whispr] Woke from sleep, restarting monitors")
            self?.keyMonitor.stop()
            self?.keyMonitor.start()
        }
    }

    func updateTriggerKey() {
        keyMonitor.triggerKeyCode = Int64(Settings.shared.triggerKeyCode)
    }

    func showOnboarding() {
        onboardingWindow.show {
            // Onboarding completed, update key binding
            self.updateTriggerKey()
        }
    }

    private func startRecording() {
        guard !appState.isRecording else { return }
        appState.isRecording = true
        appState.transcribedText = ""
        NSLog("[Whispr] Starting recording (model loaded: %@)", appState.isModelLoaded ? "true" : "false")

        popup.show()

        do {
            try audioEngine.start()
        } catch {
            NSLog("[Whispr] Failed to start audio: %@", error.localizedDescription)
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
            if !appState.isModelLoaded {
                NSLog("[Whispr] Model not loaded yet, skipping transcription")
                return
            }
            let text = await transcriber.transcribe(samples: samples)
            NSLog("[Whispr] Transcribed: %@", text)
            await MainActor.run {
                appState.transcribedText = text
                PasteService.paste(text: text)
            }
        }
    }
}

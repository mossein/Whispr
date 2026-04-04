import SwiftUI
import AppKit

struct OnboardingView: View {
    @State private var step: OnboardingStep = .welcome
    @State private var selectedKeyCode: Int = Settings.shared.triggerKeyCode
    @State private var selectedKeyName: String = Settings.shared.triggerKeyName
    @State private var isListeningForKey = false
    @State private var selectedModel: String = Settings.shared.modelName
    @State private var modelStatus: ModelStatus = .notStarted
    @State private var testTranscription: String = ""

    var onComplete: () -> Void

    enum OnboardingStep: Int, CaseIterable {
        case welcome, keybinding, modelDownload, test
    }

    enum ModelStatus {
        case notStarted, downloading, ready, failed(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                    Circle()
                        .fill(s.rawValue <= step.rawValue ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Group {
                switch step {
                case .welcome: welcomeView
                case .keybinding: keybindingView
                case .modelDownload: modelDownloadView
                case .test: testView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()

            // Navigation
            HStack {
                if step != .welcome {
                    Button("Back") {
                        step = OnboardingStep(rawValue: step.rawValue - 1)!
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                nextButton
            }
            .padding(24)
        }
        .frame(width: 500, height: 480)
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Welcome to Whispr")
                .font(.title.bold())

            Text("Voice-to-text that runs entirely on your Mac.\nNo internet required. No data leaves your device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Keybinding

    private var keybindingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Choose your trigger key")
                .font(.title2.bold())

            Text("Hold this key to record, release to transcribe and paste.")
                .foregroundStyle(.secondary)

            Button(action: { isListeningForKey.toggle() }) {
                Text(isListeningForKey ? "Press any modifier key..." : selectedKeyName)
                    .font(.title3.weight(.medium))
                    .frame(width: 260, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isListeningForKey ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(isListeningForKey ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                    )
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                presetButton("Right \u{2318}", keyCode: 0x36)
                presetButton("Right Option", keyCode: 0x3D)
                presetButton("Fn/Globe", keyCode: 0x3F)
            }
        }
        .onAppear { setupKeyListener() }
    }

    private func presetButton(_ name: String, keyCode: Int) -> some View {
        Button(action: {
            selectedKeyCode = keyCode
            selectedKeyName = name
            isListeningForKey = false
        }) {
            Text(name)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedKeyCode == keyCode ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }

    private func setupKeyListener() {
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            guard isListeningForKey else { return event }
            let code = Int(event.keyCode)
            if let name = keyName(for: code) {
                selectedKeyCode = code
                selectedKeyName = name
                isListeningForKey = false
            }
            return event
        }
    }

    private func keyName(for code: Int) -> String? {
        switch code {
        case 0x36: return "Right \u{2318}"
        case 0x37: return "Left \u{2318}"
        case 0x3A: return "Left Option"
        case 0x3D: return "Right Option"
        case 0x3B: return "Left Control"
        case 0x3E: return "Right Control"
        case 0x38: return "Left Shift"
        case 0x3C: return "Right Shift"
        case 0x3F: return "Fn/Globe"
        default: return nil
        }
    }

    // MARK: - Model Download

    private var modelDownloadView: some View {
        VStack(spacing: 16) {
            switch modelStatus {
            case .notStarted:
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
            case .downloading:
                ProgressView()
                    .controlSize(.large)
            case .ready:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
            }

            Text("Choose & Download Model")
                .font(.title2.bold())

            if case .downloading = modelStatus {
                Text("Downloading and preparing model...")
                    .foregroundStyle(.secondary)
            } else if case .ready = modelStatus {
                Text("Model is ready!")
                    .foregroundStyle(.secondary)
            } else {
                // Model picker
                VStack(spacing: 8) {
                    ForEach(Settings.availableModels) { model in
                        Button(action: { selectedModel = model.id }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.name)
                                        .font(.body.weight(.medium))
                                    Text("\(model.description) - \(model.size)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedModel == model.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedModel == model.id ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(selectedModel == model.id ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)

                if case .failed(let error) = modelStatus {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 30)
                        .lineLimit(3)
                }

                Button(case2Label) {
                    startModelDownload()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
        }
    }

    private var case2Label: String {
        if case .failed = modelStatus { return "Retry" }
        return "Download"
    }

    private func startModelDownload() {
        modelStatus = .downloading
        Settings.shared.modelName = selectedModel

        Task {
            let transcriber = AppCoordinator.shared.transcriber
            await transcriber.loadModel()

            await MainActor.run {
                if AppState.shared.isModelLoaded {
                    modelStatus = .ready
                } else {
                    modelStatus = .failed(AppState.shared.lastError ?? "Unknown error")
                }
            }
        }
    }

    // MARK: - Test

    private var appStateRef: AppState { AppState.shared }

    private var testView: some View {
        let isRecording = appStateRef.isRecording
        let transcribedText = appStateRef.transcribedText

        return VStack(spacing: 16) {
            if !testTranscription.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
            }

            Text("Test it out")
                .font(.title2.bold())

            if !testTranscription.isEmpty {
                Text("\"\(testTranscription)\"")
                    .font(.title3)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)

                Button("Try again") {
                    testTranscription = ""
                    AppState.shared.transcribedText = ""
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

            } else if isRecording {
                HStack(spacing: 2.5) {
                    ForEach(Array(appStateRef.audioLevels.enumerated()), id: \.offset) { _, level in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.accentColor)
                            .frame(width: 3, height: max(3, level * 40))
                            .animation(.linear(duration: 0.06), value: level)
                    }
                }
                .frame(height: 40)

                Text("Listening...")
                    .foregroundStyle(.secondary)

            } else {
                Text("Hold **\(selectedKeyName)** and say something\nto make sure everything works.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)

                Text("Try saying: \"Hello, Whispr!\"")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Button("Skip test") {
                    finishOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
                .font(.caption)
            }
        }
        .onChange(of: transcribedText) { _, newValue in
            if !newValue.isEmpty {
                testTranscription = newValue
            }
        }
    }

    // MARK: - Navigation

    @ViewBuilder
    private var nextButton: some View {
        switch step {
        case .welcome:
            Button("Get Started") {
                step = .keybinding
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

        case .keybinding:
            Button("Continue") {
                Settings.shared.triggerKeyCode = selectedKeyCode
                Settings.shared.triggerKeyName = selectedKeyName
                AppCoordinator.shared.updateTriggerKey()
                step = .modelDownload
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

        case .modelDownload:
            if case .ready = modelStatus {
                Button("Continue") {
                    step = .test
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                EmptyView()
            }

        case .test:
            if !testTranscription.isEmpty {
                Button("Finish Setup") {
                    finishOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                EmptyView()
            }
        }
    }

    private func finishOnboarding() {
        Settings.shared.onboardingCompleted = true
        onComplete()
    }
}

import AppKit
import SwiftUI

// MARK: - Window Controller

final class SetupWizardController {
    private var window: NSWindow?
    private var viewController: WizardViewController?

    func show() {
        if let w = window { w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }

        let vc = WizardViewController()
        vc.onComplete = { [weak self] in self?.close() }
        viewController = vc

        let w = NSWindow(contentViewController: vc)
        w.title = "Whispr Setup"
        w.styleMask = [.titled, .closable]
        w.setContentSize(NSSize(width: 520, height: 440))
        w.center()
        w.isReleasedWhenClosed = false
        w.level = .floating
        window = w

        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
        window = nil
        viewController = nil
    }
}

// MARK: - View Controller (owns all state)

final class WizardViewController: NSViewController {
    var onComplete: (() -> Void)?

    private var step = 0 { didSet { updateStep() } }
    private var selectedKeyCode: Int = Settings.shared.triggerKeyCode
    private var selectedKeyName: String = Settings.shared.triggerKeyName
    private var selectedModel: String = Settings.shared.modelName
    private var isDownloading = false
    private var modelReady = false
    private var modelError: String?
    private var keyMonitor: Any?

    private var hostingController: NSHostingController<AnyView>?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 440))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateStep()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func updateStep() {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let stepView: AnyView
        switch step {
        case 0: stepView = AnyView(makeWelcome())
        case 1: stepView = AnyView(makeKeyBinding())
        case 2: stepView = AnyView(makeModelDownload())
        case 3: stepView = AnyView(makeDone())
        default: return
        }

        let hc = NSHostingController(rootView: stepView)
        addChild(hc)
        hc.view.frame = view.bounds
        hc.view.autoresizingMask = [.width, .height]
        view.addSubview(hc.view)
        hostingController = hc

        // Start key monitor on key binding step
        if step == 1 { startKeyListener() } else { stopKeyListener() }
    }

    // MARK: - Step Views

    private func makeWelcome() -> some View {
        WizardStepLayout(
            dots: dots(),
            backAction: nil,
            nextLabel: "Get Started",
            nextAction: { [weak self] in self?.step = 1 }
        ) {
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
    }

    private func makeKeyBinding() -> some View {
        let code = selectedKeyCode
        let name = selectedKeyName
        return WizardStepLayout(
            dots: dots(),
            backAction: { [weak self] in self?.step = 0 },
            nextLabel: "Continue",
            nextAction: { [weak self] in
                guard let self else { return }
                Settings.shared.triggerKeyCode = self.selectedKeyCode
                Settings.shared.triggerKeyName = self.selectedKeyName
                AppCoordinator.shared.updateTriggerKey()
                self.step = 2
            }
        ) {
            VStack(spacing: 16) {
                Image(systemName: "keyboard")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text("Choose your trigger key")
                    .font(.title2.bold())
                Text("Hold this key to record, release to transcribe and paste.")
                    .foregroundStyle(.secondary)

                Text(name)
                    .font(.title3.weight(.medium))
                    .frame(width: 260, height: 48)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))

                HStack(spacing: 12) {
                    KeyPresetButton(label: "Right \u{2318}", isSelected: code == 0x36) { [weak self] in
                        self?.selectKey(code: 0x36, name: "Right \u{2318}")
                    }
                    KeyPresetButton(label: "Right Option", isSelected: code == 0x3D) { [weak self] in
                        self?.selectKey(code: 0x3D, name: "Right Option")
                    }
                    KeyPresetButton(label: "Fn/Globe", isSelected: code == 0x3F) { [weak self] in
                        self?.selectKey(code: 0x3F, name: "Fn/Globe")
                    }
                }

                Text("Or press any modifier key")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func makeModelDownload() -> some View {
        let downloading = isDownloading
        let ready = modelReady
        let error = modelError
        let selected = selectedModel

        return WizardStepLayout(
            dots: dots(),
            backAction: downloading ? nil : { [weak self] in self?.step = 1 },
            nextLabel: ready ? "Continue" : nil,
            nextAction: ready ? { [weak self] in self?.step = 3 } : nil
        ) {
            VStack(spacing: 16) {
                if ready {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                } else if downloading {
                    ProgressView().controlSize(.large)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                }

                Text("Download Speech Model")
                    .font(.title2.bold())

                if downloading {
                    Text("Downloading and preparing model...")
                        .foregroundStyle(.secondary)
                } else if ready {
                    Text("Model is ready!")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 6) {
                        ForEach(Settings.availableModels) { model in
                            ModelRow(model: model, isSelected: selected == model.id) { [weak self] in
                                self?.selectedModel = model.id
                                self?.updateStep()
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    if let error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .lineLimit(2)
                            .padding(.horizontal, 24)
                    }

                    Button(error != nil ? "Retry" : "Download") { [weak self] in
                        self?.startDownload()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }

    private func makeDone() -> some View {
        WizardStepLayout(
            dots: dots(),
            backAction: nil,
            nextLabel: "Get Started",
            nextAction: { [weak self] in self?.finish() }
        ) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                Text("You're all set!")
                    .font(.title.bold())
                Text("Hold **\(selectedKeyName)** to speak.\nRelease to transcribe and paste.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Helpers

    private func dots() -> (Int, Int) { (step, 4) }

    private func selectKey(code: Int, name: String) {
        selectedKeyCode = code
        selectedKeyName = name
        updateStep()
    }

    private func startKeyListener() {
        stopKeyListener()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return event }
            let code = Int(event.keyCode)
            if let name = self.keyName(for: code) {
                self.selectKey(code: code, name: name)
            }
            return event
        }
    }

    private func stopKeyListener() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
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

    private func startDownload() {
        isDownloading = true
        modelError = nil
        Settings.shared.modelName = selectedModel
        updateStep()

        Task {
            await AppCoordinator.shared.transcriber.loadModel()
            await MainActor.run {
                self.isDownloading = false
                if AppState.shared.isModelLoaded {
                    self.modelReady = true
                } else {
                    self.modelError = AppState.shared.lastError ?? "Download failed"
                }
                self.updateStep()
            }
        }
    }

    private func finish() {
        Settings.shared.onboardingCompleted = true
        AppCoordinator.shared.updateTriggerKey()
        onComplete?()
    }
}

// MARK: - Reusable SwiftUI Components

private struct WizardStepLayout<Content: View>: View {
    let dots: (Int, Int)
    let backAction: (() -> Void)?
    let nextLabel: String?
    let nextAction: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<dots.1, id: \.self) { i in
                    Circle()
                        .fill(i <= dots.0 ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation
            HStack {
                if let backAction {
                    Button("Back", action: backAction)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let nextLabel, let nextAction {
                    Button(nextLabel, action: nextAction)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 440)
    }
}

private struct KeyPresetButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ModelRow: View {
    let model: Settings.ModelOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name).font(.body.weight(.medium))
                    Text("\(model.description) - \(model.size)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

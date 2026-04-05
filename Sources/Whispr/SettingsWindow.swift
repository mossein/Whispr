import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?
    private var viewController: SettingsViewController?

    func show() {
        if let w = window { w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }

        let vc = SettingsViewController()
        viewController = vc

        let w = NSWindow(contentViewController: vc)
        w.title = "Whispr Settings"
        w.styleMask = [.titled, .closable]
        w.setContentSize(NSSize(width: 440, height: 500))
        w.center()
        w.isReleasedWhenClosed = false
        window = w

        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

final class SettingsViewController: NSViewController {
    private var selectedKeyCode: Int = Settings.shared.triggerKeyCode
    private var selectedKeyName: String = Settings.shared.triggerKeyName
    private var selectedModel: String = Settings.shared.modelName
    private var keyMonitor: Any?
    private var hostingController: NSHostingController<AnyView>?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 380))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        render()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        stopKeyListener()
    }

    private func render() {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let code = selectedKeyCode
        let name = selectedKeyName
        let model = selectedModel
        let currentModel = Settings.shared.modelName

        let content = AnyView(
            VStack(alignment: .leading, spacing: 20) {
                // Key Binding Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger Key")
                        .font(.headline)

                    Text("Hold this key to record, release to transcribe and paste.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        KeyPreset(label: "Right \u{2318}", selected: code == 0x36) { [weak self] in
                            self?.selectKey(code: 0x36, name: "Right \u{2318}")
                        }
                        KeyPreset(label: "Right Option", selected: code == 0x3D) { [weak self] in
                            self?.selectKey(code: 0x3D, name: "Right Option")
                        }
                        KeyPreset(label: "Fn/Globe", selected: code == 0x3F) { [weak self] in
                            self?.selectKey(code: 0x3F, name: "Fn/Globe")
                        }

                        Text("Current: **\(name)**")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                }

                Divider()

                // Model Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speech Model")
                        .font(.headline)

                    if model != currentModel {
                        Text("Changing model requires a restart.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    VStack(spacing: 4) {
                        ForEach(Settings.availableModels) { m in
                            Button(action: { [weak self] in
                                self?.selectedModel = m.id
                                self?.render()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(m.name).font(.body.weight(.medium))
                                        Text("\(m.description) - \(m.size)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if model == m.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(model == m.id ? Color.accentColor.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                // Save
                HStack {
                    Spacer()
                    Button("Save") { [weak self] in
                        self?.save()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
            .frame(width: 440, height: 500)
        )

        let hc = NSHostingController(rootView: content)
        addChild(hc)
        hc.view.frame = view.bounds
        hc.view.autoresizingMask = [.width, .height]
        view.addSubview(hc.view)
        hostingController = hc

        startKeyListener()
    }

    private func selectKey(code: Int, name: String) {
        selectedKeyCode = code
        selectedKeyName = name
        render()
    }

    private func startKeyListener() {
        stopKeyListener()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return event }
            let code = Int(event.keyCode)
            let names: [Int: String] = [
                0x36: "Right \u{2318}", 0x37: "Left \u{2318}",
                0x3A: "Left Option", 0x3D: "Right Option",
                0x3B: "Left Control", 0x3E: "Right Control",
                0x38: "Left Shift", 0x3C: "Right Shift",
                0x3F: "Fn/Globe"
            ]
            if let name = names[code] {
                self.selectKey(code: code, name: name)
            }
            return event
        }
    }

    private func stopKeyListener() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    private func save() {
        let modelChanged = selectedModel != Settings.shared.modelName

        Settings.shared.triggerKeyCode = selectedKeyCode
        Settings.shared.triggerKeyName = selectedKeyName
        Settings.shared.modelName = selectedModel
        AppCoordinator.shared.updateTriggerKey()

        if modelChanged {
            // Reload model
            Task {
                await AppCoordinator.shared.transcriber.loadModel()
            }
        }

        view.window?.close()
    }
}

private struct KeyPreset: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

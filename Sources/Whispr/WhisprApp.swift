import SwiftUI
import AppKit

@main
struct WhisprApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        SwiftUI.Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var observer: NSObjectProtocol?
    private var wizard: SetupWizardController?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        // Create menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Whispr")
        }

        statusMenuItem = NSMenuItem(title: "Loading model...", action: nil, keyEquivalent: "")

        let menu = NSMenu()
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit Whispr", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        _ = AppCoordinator.shared

        // Show wizard on first launch
        if !Settings.shared.onboardingCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.wizard = SetupWizardController()
                self?.wizard?.show()
            }
        }

        // Update menu status when model loads
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            self?.updateStatus()
            if AppState.shared.isModelLoaded || AppState.shared.lastError != nil {
                timer.invalidate()
            }
        }

        NSLog("[Whispr] App started")
    }

    private func updateStatus() {
        let state = AppState.shared
        if state.isModelLoading {
            statusMenuItem.title = state.modelLoadProgress
            statusItem.button?.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Downloading")
        } else if state.isModelLoaded {
            statusMenuItem.title = "Ready - Hold \(Settings.shared.triggerKeyName)"
            statusItem.button?.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Whispr")
        } else if let error = state.lastError {
            statusMenuItem.title = "Error: \(error)"
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        settingsWindow?.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

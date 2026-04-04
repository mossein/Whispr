import SwiftUI
import AppKit

@main
struct WhisprApp: App {
    @State private var appState = AppState.shared

    init() {
        NSApp?.setActivationPolicy(.accessory)

        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        _ = AppCoordinator.shared
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: appState.isRecording ? "mic.fill" : "mic")
        }
    }
}

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isModelLoading {
            Text(appState.modelLoadProgress)
        } else if appState.isModelLoaded {
            Text("Ready - Hold \(Settings.shared.triggerKeyName)")
        } else {
            Text("Loading...")
        }

        if let error = appState.lastError {
            Divider()
            Text(error).foregroundStyle(.red)
        }

        Divider()
        Button("Quit") { NSApp?.terminate(nil) }
            .keyboardShortcut("q")
    }
}

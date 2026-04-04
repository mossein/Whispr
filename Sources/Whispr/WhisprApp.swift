import SwiftUI

@main
struct WhisprApp: App {
    @State private var appState = AppState.shared
    private let coordinator = AppCoordinator.shared

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
        VStack(alignment: .leading, spacing: 4) {
            if appState.isModelLoading {
                Text(appState.modelLoadProgress)
                    .font(.caption)
            } else if appState.isModelLoaded {
                Text("Ready - Hold Right \u{2318} to speak")
                    .font(.caption)
            } else {
                Text("Model not loaded")
                    .font(.caption)
            }

            if let error = appState.lastError {
                Divider()
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            Button("Quit Whispr") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

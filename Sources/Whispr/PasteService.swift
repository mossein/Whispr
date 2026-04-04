import AppKit
import CoreGraphics

enum PasteService {
    static func paste(text: String) {
        guard !text.isEmpty else { return }

        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Try to simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if AXIsProcessTrusted() {
                simulateCmdV()
            } else {
                NSLog("[Whispr] No accessibility - text copied to clipboard only")
            }
        }
    }

    private static func simulateCmdV() {
        let vKeyCode: CGKeyCode = 9

        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}

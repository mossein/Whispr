import AppKit
import Carbon

enum PasteService {
    static func paste(text: String) {
        guard !text.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            postCmdV()
        }
    }

    private static func postCmdV() {
        // Use CGEvent with .cghidEventTap which doesn't need accessibility
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            NSLog("[Whispr] Failed to create event source")
            return
        }

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: false) else {
            NSLog("[Whispr] Failed to create key events")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

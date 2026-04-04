import Cocoa
import CoreGraphics

final class KeyMonitor {
    private var flagsMonitor: Any?
    private var isKeyDown = false

    var onRightCommandDown: (() -> Void)?
    var onRightCommandUp: (() -> Void)?

    var triggerKeyCode: Int64 = 0x36

    func start() {
        // Use both local and global monitors for full coverage
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
        }

        // Also monitor locally (when our own windows are focused)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
            return event
        }

        NSLog("[Whispr] Key monitor started (NSEvent)")
    }

    private func handleFlags(_ event: NSEvent) {
        let keyCode = Int64(event.keyCode)
        guard keyCode == triggerKeyCode else { return }

        let commandDown = event.modifierFlags.contains(.command)

        if commandDown && !isKeyDown {
            isKeyDown = true
            NSLog("[Whispr] Right Cmd DOWN")
            onRightCommandDown?()
        } else if !commandDown && isKeyDown {
            isKeyDown = false
            NSLog("[Whispr] Right Cmd UP")
            onRightCommandUp?()
        }
    }

    func stop() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }
}

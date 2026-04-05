import Cocoa
import CoreGraphics

final class KeyMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isKeyDown = false

    var onRightCommandDown: (() -> Void)?
    var onRightCommandUp: (() -> Void)?

    var triggerKeyCode: Int64 = 0x36

    func start() {
        stop() // Clean up any existing monitors first

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
            return event
        }

        NSLog("[Whispr] Key monitor started")
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
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isKeyDown = false
    }
}

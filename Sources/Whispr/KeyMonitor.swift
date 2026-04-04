import Cocoa
import CoreGraphics

final class KeyMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onRightCommandDown: (() -> Void)?
    var onRightCommandUp: (() -> Void)?

    private static let rightCommandKeyCode: Int64 = 0x36

    func start() {
        let eventMask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: KeyMonitor.eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[Whispr] Failed to create event tap. Check Accessibility permissions.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[Whispr] Key monitor started")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
        let monitor = Unmanaged<KeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .flagsChanged {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == KeyMonitor.rightCommandKeyCode {
                let flags = event.flags
                let commandDown = flags.contains(.maskCommand)
                print("[Whispr] Right Cmd \(commandDown ? "DOWN" : "UP")")
                DispatchQueue.main.async {
                    if commandDown {
                        monitor.onRightCommandDown?()
                    } else {
                        monitor.onRightCommandUp?()
                    }
                }
            }
        }

        return Unmanaged.passUnretained(event)
    }
}

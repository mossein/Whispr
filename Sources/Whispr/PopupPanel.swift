import AppKit
import SwiftUI

final class PopupPanel {
    private var panel: FloatingPanel?
    private let appState = AppState.shared

    func show() {
        if let existing = panel {
            existing.orderFront(nil)
            return
        }

        let contentView = PopupContentView()
            .environment(appState)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 80)

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 80),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Center on screen
        if let screen = NSScreen.main {
            let x = (screen.visibleFrame.width - 320) / 2 + screen.visibleFrame.origin.x
            let y = (screen.visibleFrame.height - 80) / 2 + screen.visibleFrame.origin.y
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.alphaValue = 0
        panel.orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 1
        }

        self.panel = panel
    }

    func dismiss() {
        guard let panel = panel else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.panel = nil
        })
    }
}

final class FloatingPanel: NSPanel {
    override var canBecomeMain: Bool { false }
    override var canBecomeKey: Bool { false }
}

struct PopupContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(appState.audioLevels.enumerated()), id: \.offset) { _, level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 4, height: max(4, level * 50))
                    .animation(.interpolatingSpring(stiffness: 300, damping: 15), value: level)
            }
        }
        .frame(width: 300, height: 60)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 5)
        )
    }
}

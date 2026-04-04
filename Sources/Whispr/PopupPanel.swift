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
        hostingView.frame = NSRect(x: 0, y: 0, width: 280, height: 64)

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 64),
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
            let x = (screen.visibleFrame.width - 280) / 2 + screen.visibleFrame.origin.x
            let y = (screen.visibleFrame.height - 64) / 2 + screen.visibleFrame.origin.y
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.alphaValue = 0
        panel.orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            panel.animator().alphaValue = 1
        }

        self.panel = panel
    }

    func dismiss() {
        guard let panel = panel else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.08
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
        HStack(spacing: 2.5) {
            ForEach(Array(appState.audioLevels.enumerated()), id: \.offset) { index, level in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white.opacity(0.85))
                    .frame(width: 3, height: max(3, level * 40))
                    .animation(.linear(duration: 0.06), value: level)
            }
        }
        .frame(width: 260, height: 44)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 16, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

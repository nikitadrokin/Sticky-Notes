import AppKit
import SwiftUI

/// A borderless panel that can become key (so its TextEditor accepts typing)
/// without activating the whole app.
final class NotePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Manages one floating glass sticky note on the desktop.
@MainActor
final class NoteWindowController: NSObject, NSWindowDelegate {
    let note: Note
    private weak var appState: AppState?
    private let panel: NotePanel

    /// While a programmatic dock animation runs we ignore move callbacks.
    private var isDocking = false

    init(note: Note, appState: AppState) {
        self.note = note
        self.appState = appState

        let size = NSSize(width: note.width, height: note.height)
        let origin = NoteWindowController.startOrigin(for: note, size: size)

        panel = NotePanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.hidesOnDeactivate = false
        panel.minSize = NSSize(width: 180, height: 160)
        panel.delegate = self

        let root = NoteView(
            note: note,
            appState: appState,
            onDock: { [weak appState, weak self] in
                guard let self, let appState else { return }
                appState.dockWindow(for: self.note)
            },
            onDelete: { [weak appState, weak self] in
                guard let self, let appState else { return }
                appState.delete(self.note)
            }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = panel.contentLayoutRect
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
    }

    func show() {
        panel.makeKeyAndOrderFront(nil)
    }

    func orderOut() {
        panel.orderOut(nil)
    }

    /// Slide the panel into the left wall, then run `completion`.
    func animateDock(completion: @escaping () -> Void) {
        isDocking = true
        guard let screen = panel.screen ?? NSScreen.main else { completion(); return }
        let target = panel.frame.offsetBy(dx: screen.visibleFrame.minX - panel.frame.maxX, dy: 0)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.24
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 0
        } completionHandler: {
            completion()
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        guard !isDocking else { return }
        note.posX = panel.frame.minX
        note.posY = panel.frame.minY
        // Shove against the left wall to dock.
        if let screen = panel.screen ?? NSScreen.main,
           panel.frame.minX <= screen.visibleFrame.minX + 8 {
            appState?.dockWindow(for: note)
        }
    }

    func windowDidResize(_ notification: Notification) {
        note.width = panel.frame.width
        note.height = panel.frame.height
    }

    // MARK: - Placement

    private static func startOrigin(for note: Note, size: NSSize) -> NSPoint {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        if note.posX != 0 || note.posY != 0 {
            return NSPoint(x: note.posX, y: note.posY)
        }
        // First open: cascade near the left-center, just right of the island.
        let x = screen.minX + 264
        let y = screen.midY - size.height / 2
        return NSPoint(x: x, y: y)
    }
}

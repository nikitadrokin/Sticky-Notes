import AppKit
import SwiftUI

/// The glass "island" that slides out from the left edge and hosts the note tray.
@MainActor
final class IslandController {
    private let appState: AppState
    private var panel: NSPanel?
    private var hideWorkItem: DispatchWorkItem?

    private let islandWidth: CGFloat = 232
    private let heightFraction: CGFloat = 0.6

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Show / hide

    func show(besideStrip strip: NSRect, on screen: NSScreen) {
        hideWorkItem?.cancel()
        appState.refresh()

        let panel = panel ?? makePanel()
        self.panel = panel

        let visible = screen.visibleFrame
        let height = visible.height * heightFraction
        let shownFrame = NSRect(
            x: visible.minX + 8,
            y: visible.midY - height / 2,
            width: islandWidth,
            height: height
        )
        // Start just off the left edge for the slide-in.
        let hiddenFrame = shownFrame.offsetBy(dx: -(islandWidth + 16), dy: 0)

        if panel.alphaValue == 0 || !panel.isVisible {
            panel.setFrame(hiddenFrame, display: false)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(shownFrame, display: true)
            panel.animator().alphaValue = 1
        }
    }

    private func scheduleHide() {
        hideWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.hide() }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func hide() {
        guard let panel else { return }
        let target = panel.frame.offsetBy(dx: -(islandWidth + 16), dy: 0)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak panel] in
            panel?.orderOut(nil)
        }
    }

    // MARK: - Panel

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: islandWidth, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.alphaValue = 0

        let root = IslandView(
            appState: appState,
            onHoverChange: { [weak self] inside in
                if inside { self?.hideWorkItem?.cancel() } else { self?.scheduleHide() }
            }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = panel.contentLayoutRect
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
        return panel
    }
}

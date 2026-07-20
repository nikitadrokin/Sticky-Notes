import AppKit
import SwiftUI

/// The glass "island" that slides out from the left edge and hosts the note tray.
@MainActor
final class IslandController {
  private let appState: AppState
  private var panel: NSPanel?
  private let presenter = IslandPresenter()

  /// Matches the SwiftUI spring so we don't order the panel out mid-morph.
  private let revealDuration: TimeInterval = 0.5

  private let islandWidth: CGFloat = 232
  private let heightFraction: CGFloat = 0.6

  init(appState: AppState) {
    self.appState = appState
  }

  // MARK: - Show / hide

  func show(besideStrip strip: NSRect, on screen: NSScreen) {
    appState.refresh()

    let panel = panel ?? makePanel()
    self.panel = panel

    let visible = screen.visibleFrame
    let height = visible.height * heightFraction
    // Flush to the very edge (nudged 1pt off-screen) so the inverted
    // corners fuse into the wall instead of floating beside it. The panel stays
    // pinned here; the emergence is drawn inside SwiftUI via the shape morph.
    let shownFrame = NSRect(
      x: visible.minX - 1,
      y: visible.midY - height / 2,
      width: islandWidth,
      height: height
    )

    panel.setFrame(shownFrame, display: true)
    panel.alphaValue = 1
    panel.orderFrontRegardless()
    // Kick the SwiftUI spring: shape sweeps out from the wall and radii bloom.
    presenter.isShown = true
  }

  private func hide() {
    guard let panel else { return }
    // Retract by reversing the SwiftUI morph, then order the panel out once the
    // spring has settled back into the wall.
    presenter.isShown = false
    let work = DispatchWorkItem { [weak self, weak panel] in
      guard let self, let panel else { return }
      // Don't yank it away if a new hover re-triggered the reveal in the meantime.
      if !self.presenter.isShown { panel.orderOut(nil) }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + revealDuration, execute: work)
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
    // Match the hot zone: desktop-space only, never over a full-screen app.
    panel.collectionBehavior = [.stationary, .ignoresCycle]
    panel.hidesOnDeactivate = false
    panel.alphaValue = 0

    let root = IslandView(
      appState: appState,
      presenter: presenter,
      onHoverChange: { [weak self] inside in
        // Close the moment the cursor leaves — no timer, so a fresh hover can't
        // be clobbered by a stale scheduled hide firing right after it reopens.
        if !inside { self?.hide() }
      }
    )
    let hosting = NSHostingView(rootView: root)
    hosting.frame = panel.contentLayoutRect
    hosting.autoresizingMask = [.width, .height]
    panel.contentView = hosting
    return panel
  }
}

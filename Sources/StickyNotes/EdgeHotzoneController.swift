import AppKit
import SwiftUI

/// Owns the invisible edge "hot zone" strip on the left-center of the screen and
/// the glass island that slides out when the cursor touches it.
@MainActor
final class EdgeHotzoneController {
  private let appState: AppState

  private var hotzone: NSPanel?
  private let island: IslandController

  /// Geometry of the hot zone strip.
  private let stripWidth: CGFloat = 6
  private let stripHeightFraction: CGFloat = 0.42

  init(appState: AppState) {
    self.appState = appState
    self.island = IslandController(appState: appState)
  }

  func install() {
    guard let screen = NSScreen.main else { return }
    let visible = screen.visibleFrame

    let height = visible.height * stripHeightFraction
    let frame = NSRect(
      x: visible.minX,
      y: visible.midY - height / 2,
      width: stripWidth,
      height: height
    )

    let panel = NSPanel(
      contentRect: frame,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.ignoresMouseEvents = false
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    panel.hidesOnDeactivate = false

    let tracker = TrackingView(frame: NSRect(origin: .zero, size: frame.size))
    tracker.autoresizingMask = [.width, .height]
    // A faint always-visible hint so the user knows where to reach.
    tracker.wantsLayer = true
    tracker.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
    tracker.layer?.cornerRadius = stripWidth / 2

    tracker.onEnter = { [weak self] in
      guard let self else { return }
      self.island.show(besideStrip: frame, on: screen)
    }
    panel.contentView = tracker

    panel.orderFrontRegardless()
    self.hotzone = panel
  }
}

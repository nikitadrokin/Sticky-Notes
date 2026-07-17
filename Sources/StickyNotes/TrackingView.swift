import AppKit

/// A view that reports mouse enter/exit, active even when the app is in the
/// background (accessory apps are never the "active" app).
final class TrackingView: NSView {
  var onEnter: (() -> Void)?
  var onExit: (() -> Void)?

  private var trackingArea: NSTrackingArea?

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let trackingArea { removeTrackingArea(trackingArea) }
    let area = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(area)
    trackingArea = area
  }

  override func mouseEntered(with event: NSEvent) { onEnter?() }
  override func mouseExited(with event: NSEvent) { onExit?() }
}

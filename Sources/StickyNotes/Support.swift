import AppKit
import SwiftUI

extension Color {
  /// Build a color from a "#RRGGBB" hex string.
  init(hex: String) {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") { s.removeFirst() }
    var value: UInt64 = 0
    Scanner(string: s).scanHexInt64(&value)
    let r = Double((value & 0xFF0000) >> 16) / 255.0
    let g = Double((value & 0x00FF00) >> 8) / 255.0
    let b = Double(value & 0x0000FF) / 255.0
    self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
  }

  /// Convert to a "#RRGGBB" hex string (sRGB), or nil if it can't be resolved.
  func toHex() -> String? {
    guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return nil }
    let r = Int((rgb.redComponent * 255).rounded())
    let g = Int((rgb.greenComponent * 255).rounded())
    let b = Int((rgb.blueComponent * 255).rounded())
    return String(format: "#%02X%02X%02X", r, g, b)
  }
}

extension Note {
  /// First non-empty line, used as the tray label.
  var title: String {
    let first = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
    let trimmed = first.trimmingCharacters(in: .whitespaces)
    return trimmed.isEmpty ? "New Note" : trimmed
  }
}

/// Reports mouse enter/exit for a SwiftUI region using an always-active tracking
/// area — needed because our windows belong to a background (accessory) app,
/// where SwiftUI's own `.onHover` may not fire.
struct HoverTracking: NSViewRepresentable {
  var onChange: (Bool) -> Void

  func makeNSView(context: Context) -> TrackingView {
    let view = TrackingView()
    view.onEnter = { onChange(true) }
    view.onExit = { onChange(false) }
    return view
  }

  func updateNSView(_ nsView: TrackingView, context: Context) {}
}

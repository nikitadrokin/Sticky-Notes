import AppKit
import SwiftUI

/// A rounded rectangle that fuses to the left screen edge. The trailing (right)
/// corners are convex (normal rounding). The wall side is the *tallest* part of
/// the shape: the flat top/bottom edges are inset toward the middle by `topRaise`,
/// and the wall-side corners sweep back *out* to the wall through convex hooks — so
/// the island bulges into raised lips where it meets the edge instead of rounding in.
struct EdgeBlobShape: Shape {
  /// Convex rounding on the trailing (right) corners.
  var trailingRadius: CGFloat = 26
  /// How far the flat top/bottom edges sit inset from the raised wall lips.
  /// Doubles as the wall-corner hook radius, so a larger value = rounder hooks.
  var topRaise: CGFloat = 30

  func path(in rect: CGRect) -> Path {
    let w = rect.width
    let h = rect.height
    // Clamp so the radii never overlap on short/narrow islands.
    let cr = min(trailingRadius, w / 2, h / 2 - 1)
    let raise = min(topRaise, w - cr, h / 2 - 1)

    var p = Path()
    // Wall top — the highest point, flush to the left edge.
    p.move(to: CGPoint(x: 0, y: 0))
    // Convex hook: rise from the inset flat top edge up to the wall top.
    p.addArc(
      center: CGPoint(x: raise, y: 0), radius: raise,
      startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
    // Flat top edge → trailing top corner (convex).
    p.addLine(to: CGPoint(x: w - cr, y: raise))
    p.addArc(
      center: CGPoint(x: w - cr, y: raise + cr), radius: cr,
      startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
    // Trailing edge → trailing bottom corner (convex).
    p.addLine(to: CGPoint(x: w, y: h - raise - cr))
    p.addArc(
      center: CGPoint(x: w - cr, y: h - raise - cr), radius: cr,
      startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
    // Flat bottom edge → convex hook dropping back down to the wall bottom.
    p.addLine(to: CGPoint(x: raise, y: h - raise))
    p.addArc(
      center: CGPoint(x: raise, y: h), radius: raise,
      startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
    // Up the full-height wall back to the start.
    p.closeSubpath()
    return p
  }
}

/// The tray of notes shown inside the glass island.
struct IslandView: View {
  let appState: AppState
  var onHoverChange: (Bool) -> Void

  var body: some View {
    VStack(spacing: 12) {
      Button {
        appState.newNote()
      } label: {
        Label("New Note", systemImage: "plus")
          .font(.system(size: 13, weight: .semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
      }
      .buttonStyle(.glassProminent)

      ScrollView(.vertical, showsIndicators: false) {
        GlassEffectContainer(spacing: 8) {
          VStack(spacing: 8) {
            if appState.notes.isEmpty {
              Text("No notes yet")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
            ForEach(appState.notes) { note in
              tab(for: note)
            }
          }
        }
      }

      Divider().opacity(0.3)

      HStack {
        Spacer(minLength: 0)
        Button {
          NSApp.terminate(nil)
        } label: {
          Image(systemName: "power")
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 28, height: 28)
            .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .help("Quit Sticky Notes (⌘Q)")
        // Command-Q quits while the tray is open.
        .keyboardShortcut("q", modifiers: .command)
      }
    }
    // Extra top/bottom inset keeps content clear of the raised wall-side lips.
    .padding(EdgeInsets(top: 44, leading: 14, bottom: 44, trailing: 14))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .glassEffect(.regular, in: EdgeBlobShape())
    .background(HoverTracking(onChange: onHoverChange))
  }

  private func tab(for note: Note) -> some View {
    Button {
      appState.openWindow(for: note)
    } label: {
      HStack(spacing: 10) {
        Circle()
          .fill(Color(hex: note.colorHex))
          .frame(width: 12, height: 12)
        Text(note.title)
          .font(.system(size: 13, weight: .medium))
          .lineLimit(1)
        Spacer(minLength: 0)
        if appState.isOpen(note) {
          Image(systemName: "circle.fill")
            .font(.system(size: 6))
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button(role: .destructive) {
        appState.delete(note)
      } label: {
        Label("Delete Note", systemImage: "trash")
      }
    }
  }
}

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
  /// Emergence progress. 0 = retracted into the wall (thin sliver, tight radii),
  /// 1 = fully bulged out to its resting shape. Interpolating this makes the
  /// island appear to morph out of the screen edge rather than slide in flat.
  var reveal: CGFloat = 1

  // Drive the whole morph off a single interpolated value.
  var animatableData: CGFloat {
    get { reveal }
    set { reveal = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let r = max(0, min(1, reveal))
    let h = rect.height
    // `inset` is the CONSTANT vertical padding — the gap between the frame edge
    // and the flat top/bottom edges of the body. It never animates, so the shape
    // always keeps its hardcoded padding and never stretches to the true y=0 / y=h
    // of the panel frame. Only the *lip* (how far the wall-side corners bulge past
    // the flat edge, out toward y=0 / y=h) grows with `reveal`.
    let inset = max(0, min(topRaise, h / 2 - 1))
    let lip = inset * r
    // The trailing edge sweeps out from the wall as we emerge.
    let w = max(1, rect.width * r)
    // Trailing corner radius blooms with reveal, clamped so it never overlaps.
    let cr = max(0, min(trailingRadius, w / 2, h / 2 - inset - 1) * r)

    // Vertical extents: the flat body edges are fixed at `inset` / `h - inset`;
    // the wall-side lips protrude to `inset - lip` / `h - inset + lip`.
    let topFlat = inset
    let botFlat = h - inset
    let topWall = inset - lip
    let botWall = h - inset + lip

    var p = Path()
    // Wall top — the highest point of the (animating) lip, flush to the left edge.
    p.move(to: CGPoint(x: 0, y: topWall))
    // Convex hook: rise from the flat top edge up to the wall lip.
    p.addArc(
      center: CGPoint(x: lip, y: topWall), radius: lip,
      startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
    // Flat top edge → trailing top corner (convex).
    p.addLine(to: CGPoint(x: w - cr, y: topFlat))
    p.addArc(
      center: CGPoint(x: w - cr, y: topFlat + cr), radius: cr,
      startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
    // Trailing edge → trailing bottom corner (convex).
    p.addLine(to: CGPoint(x: w, y: botFlat - cr))
    p.addArc(
      center: CGPoint(x: w - cr, y: botFlat - cr), radius: cr,
      startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
    // Flat bottom edge → convex hook dropping back down to the wall lip.
    p.addLine(to: CGPoint(x: lip, y: botFlat))
    p.addArc(
      center: CGPoint(x: lip, y: botWall), radius: lip,
      startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
    // Up the wall (inset..inset, plus lips) back to the start.
    p.closeSubpath()
    return p
  }
}

/// Drives the island's emerge/retract animation. The controller flips `isShown`;
/// the SwiftUI view interpolates the shape's `reveal` in response.
@MainActor
@Observable
final class IslandPresenter {
  var isShown = false
}

/// The tray of notes shown inside the glass island.
struct IslandView: View {
  let appState: AppState
  let presenter: IslandPresenter
  var onHoverChange: (Bool) -> Void

  /// The blob shape at the current emergence progress.
  private var blob: EdgeBlobShape {
    EdgeBlobShape(reveal: presenter.isShown ? 1 : 0)
  }

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
    .glassEffect(.regular, in: blob)
    // Clip the tray to the growing blob so the content emerges *with* the glass
    // instead of appearing at full width behind a small shape.
    .mask(blob)
    // Fade the contents in a touch behind the leading edge of the morph.
    .opacity(presenter.isShown ? 1 : 0)
    // A single spring drives both the width sweep and the blooming radii.
    .animation(.spring(response: 0.42, dampingFraction: 0.82), value: presenter.isShown)
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

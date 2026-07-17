import SwiftUI
import AppKit

/// A rounded rectangle that fuses to the left screen edge. The trailing (right)
/// corners are convex (normal rounding). The wall side spans the *full* height and
/// is the tallest part of the shape: the top and bottom edges are inset and sweep
/// back out to the wall through a concave cove, so the island reads as if it
/// bulged *out* of the side of the screen rather than pinching in at a neck.
struct EdgeBlobShape: Shape {
    /// Convex rounding on the trailing (right) corners.
    var trailingRadius: CGFloat = 26
    /// Concave cove where the top/bottom edges flare out to meet the left wall.
    var filletRadius: CGFloat = 22

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        // Clamp so the radii never overlap on short/narrow islands.
        let cr = min(trailingRadius, w / 2, h / 2 - 1)
        let fr = min(filletRadius, w - cr, h / 2 - 1)

        var p = Path()
        // Start at the top of the wall (tallest point).
        p.move(to: CGPoint(x: 0, y: 0))
        // Top cove: flare from the wall out to the inset top edge (concave).
        p.addArc(center: CGPoint(x: fr, y: 0), radius: fr,
                 startAngle: .degrees(180), endAngle: .degrees(90), clockwise: false)
        // Flat top edge → trailing top corner (convex).
        p.addLine(to: CGPoint(x: w - cr, y: fr))
        p.addArc(center: CGPoint(x: w - cr, y: fr + cr), radius: cr,
                 startAngle: .degrees(270), endAngle: .degrees(360), clockwise: true)
        // Trailing edge → trailing bottom corner (convex).
        p.addLine(to: CGPoint(x: w, y: h - fr - cr))
        p.addArc(center: CGPoint(x: w - cr, y: h - fr - cr), radius: cr,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: true)
        // Flat bottom edge → bottom cove flaring back to the wall (concave).
        p.addLine(to: CGPoint(x: fr, y: h - fr))
        p.addArc(center: CGPoint(x: fr, y: h), radius: fr,
                 startAngle: .degrees(270), endAngle: .degrees(180), clockwise: false)
        // Down the full-height wall back to the start.
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
        // Extra leading inset keeps content clear of the wall-side coves.
        .padding(EdgeInsets(top: 14, leading: 22, bottom: 14, trailing: 14))
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

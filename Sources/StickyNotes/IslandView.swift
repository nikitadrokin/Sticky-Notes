import SwiftUI
import AppKit

/// A rounded rectangle that fuses to the left screen edge: the trailing corners
/// are convex (normal rounding), while the two corners touching the wall use an
/// *inverted* (concave) fillet. The flat top and bottom edges overhang the
/// narrower neck at the wall, so the island reads as if it "blobbed" out of the
/// side of the screen rather than floating beside it.
struct EdgeBlobShape: Shape {
    /// Convex rounding on the trailing (right) corners.
    var trailingRadius: CGFloat = 26
    /// Concave rounding where the top/bottom edges meet the left wall.
    var filletRadius: CGFloat = 22

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        // Clamp so the two radii never overlap on short/narrow islands.
        let cr = min(trailingRadius, w / 2, h / 2)
        let fr = min(filletRadius, w - cr, h / 2 - 1)

        var p = Path()
        // Start at the flat top, just past the leading fillet.
        p.move(to: CGPoint(x: fr, y: 0))
        // Flat top edge → trailing top corner (convex).
        p.addLine(to: CGPoint(x: w - cr, y: 0))
        p.addArc(center: CGPoint(x: w - cr, y: cr), radius: cr,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // Trailing edge → trailing bottom corner (convex).
        p.addLine(to: CGPoint(x: w, y: h - cr))
        p.addArc(center: CGPoint(x: w - cr, y: h - cr), radius: cr,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // Flat bottom edge → bottom-left inverted fillet (concave).
        p.addLine(to: CGPoint(x: fr, y: h))
        p.addArc(center: CGPoint(x: fr, y: h - fr), radius: fr,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: true)
        // Wall contact (narrow neck) → top-left inverted fillet (concave).
        p.addLine(to: CGPoint(x: 0, y: fr))
        p.addArc(center: CGPoint(x: fr, y: fr), radius: fr,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: true)
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
        // Extra leading inset keeps content clear of the narrow neck at the wall.
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

import SwiftUI
import AppKit

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

            Divider().opacity(0.3)

            HStack {
                Spacer(minLength: 0)
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
                .help("Quit Sticky Notes (⌘Q)")
                // Command-Q quits while the tray is open.
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
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
            .background(.white.opacity(0.08), in: .rect(cornerRadius: 12))
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

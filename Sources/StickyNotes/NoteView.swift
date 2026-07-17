import SwiftUI
import AppKit

/// A single floating glass sticky note.
struct NoteView: View {
    @Bindable var note: Note
    let appState: AppState
    var onDock: () -> Void
    var onDelete: () -> Void

    @State private var showControls = false

    var body: some View {
        VStack(spacing: 0) {
            header
            TextEditor(text: $note.text)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .background(.clear)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .onChange(of: note.text) { _, _ in
                    appState.touch(note)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(
            .regular.tint(Color(hex: note.colorHex).opacity(0.55)).interactive(),
            in: .rect(cornerRadius: 22)
        )
        .background(HoverTracking { showControls = $0 })
    }

    private var header: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                // Dock back to the edge.
                controlButton(system: "chevron.left", help: "Dock to edge", action: onDock)

                // Color picker.
                Menu {
                    ForEach(NotePalette.default, id: \.self) { hex in
                        Button {
                            note.colorHex = hex
                            appState.save()
                        } label: {
                            Label {
                                Text(hex)
                            } icon: {
                                Circle().fill(Color(hex: hex))
                            }
                        }
                    }
                } label: {
                    Circle()
                        .fill(Color(hex: note.colorHex))
                        .frame(width: 14, height: 14)
                        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1))
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .fixedSize()
                .help("Change color")

                Spacer(minLength: 0)

                controlButton(system: "trash", help: "Delete note", action: onDelete)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .opacity(showControls ? 1 : 0.0)
        .animation(.easeInOut(duration: 0.15), value: showControls)
        // The header doubles as the drag handle (panel is movable by background).
        .contentShape(Rectangle())
    }

    private func controlButton(system: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .help(help)
    }
}

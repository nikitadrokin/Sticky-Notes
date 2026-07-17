import AppKit
import SwiftUI

/// A single floating glass sticky note.
struct NoteView: View {
  @Bindable var note: Note
  let appState: AppState
  var onDock: () -> Void
  var onDelete: () -> Void

  @State private var showControls = false

  /// Bound selection for the palette picker.
  private var colorSelection: Binding<String> {
    Binding(
      get: { note.colorHex },
      set: {
        note.colorHex = $0
        appState.save()
      }
    )
  }

  /// Bound Color for the native color wheel.
  private var customColor: Binding<Color> {
    Binding(
      get: { Color(hex: note.colorHex) },
      set: {
        note.colorHex = $0.toHex() ?? note.colorHex
        appState.save()
      }
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      TextEditor(text: $note.text)
        .font(.system(size: 14))
        .scrollContentBackground(.hidden)
        .background(.clear)
        .padding(.horizontal, 12)
        .padding(.top, showControls ? 0 : 12)
        .padding(.bottom, 12)
        .onChange(of: note.text) { _, _ in
          appState.touch(note)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(.easeInOut(duration: 0.2), value: showControls)
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
          Picker("Color", selection: colorSelection) {
            ForEach(NotePalette.colors, id: \.self) { color in
              Label {
                Text(color.name)
              } icon: {
                Image(systemName: "circle.fill")
                  .foregroundStyle(Color(hex: color.hex))
              }
              .tag(color.hex)
            }
          }
          .pickerStyle(.inline)
          .labelsHidden()

          Divider()

          ColorPicker("Custom color…", selection: customColor, supportsOpacity: false)
        } label: {
          Image(systemName: "paintpalette.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(hex: note.colorHex))
            .frame(width: 28, height: 28)
            .contentShape(Circle())
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .fixedSize()
        .help("Change color — \(NotePalette.name(for: note.colorHex))")

        Spacer(minLength: 0)

        controlButton(system: "trash", help: "Delete note", action: onDelete)
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 10)
    .padding(.bottom, 4)
    .opacity(showControls ? 1 : 0.0)
    .frame(height: showControls ? nil : 0, alignment: .top)
    .clipped()
    // The header doubles as the drag handle (panel is movable by background).
    .contentShape(Rectangle())
  }

  private func controlButton(system: String, help: String, action: @escaping () -> Void)
    -> some View
  {
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

import Foundation
import SwiftData

/// A single sticky note. Persisted with SwiftData.
@Model
final class Note {
  /// The note's body text.
  var text: String
  /// Hex string of the note's tint color, e.g. "#FFD60A".
  var colorHex: String
  var createdAt: Date
  var lastEdited: Date

  /// Saved on-screen frame of the floating panel (bottom-left origin, AppKit coords).
  var posX: Double
  var posY: Double
  var width: Double
  var height: Double

  /// Whether this note currently has a floating panel on the desktop.
  /// Used to restore open notes across launches.
  var isOpen: Bool

  init(text: String = "", colorHex: String = NotePalette.default.first ?? "#FFD60A") {
    self.text = text
    self.colorHex = colorHex
    self.createdAt = .now
    self.lastEdited = .now
    self.posX = 0
    self.posY = 0
    self.width = 260
    self.height = 260
    self.isOpen = false
  }
}

/// A named tint color a note can use.
struct NoteColor: Hashable {
  let name: String
  let hex: String
}

/// The palette of tint colors a note can use.
enum NotePalette {
  static let colors: [NoteColor] = [
    NoteColor(name: "Yellow", hex: "#FFD60A"),
    NoteColor(name: "Orange", hex: "#FF9F0A"),
    NoteColor(name: "Pink", hex: "#FF6482"),
    NoteColor(name: "Purple", hex: "#BF5AF2"),
    NoteColor(name: "Blue", hex: "#5AC8FA"),
    NoteColor(name: "Green", hex: "#30D158"),
  ]

  static let `default`: [String] = colors.map(\.hex)

  /// Human-readable name for a hex value, falling back to "Custom".
  static func name(for hex: String) -> String {
    colors.first { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }?.name ?? "Custom"
  }
}

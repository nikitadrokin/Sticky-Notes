import AppKit
import Observation
import SwiftData

/// Central app state: owns the SwiftData store, the list of notes, and the
/// floating note windows currently on the desktop.
@MainActor
@Observable
final class AppState {
  let container: ModelContainer
  var notes: [Note] = []

  /// Live note windows keyed by the note's persistent id.
  @ObservationIgnored
  private var controllers: [PersistentIdentifier: NoteWindowController] = [:]

  var context: ModelContext { container.mainContext }

  init(container: ModelContainer) {
    self.container = container
  }

  // MARK: - Fetching

  func refresh() {
    let descriptor = FetchDescriptor<Note>(
      sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
    )
    notes = (try? context.fetch(descriptor)) ?? []
  }

  func save() {
    try? context.save()
  }

  // MARK: - Note lifecycle

  @discardableResult
  func newNote() -> Note {
    let note = Note()
    context.insert(note)
    save()
    refresh()
    openWindow(for: note)
    return note
  }

  func delete(_ note: Note) {
    closeWindow(for: note)
    context.delete(note)
    save()
    refresh()
  }

  func touch(_ note: Note) {
    note.lastEdited = .now
    save()
  }

  // MARK: - Windows

  var isOpen: (Note) -> Bool {
    { [weak self] note in self?.controllers[note.persistentModelID] != nil }
  }

  func openWindow(for note: Note) {
    if let existing = controllers[note.persistentModelID] {
      existing.show()
      return
    }
    let controller = NoteWindowController(note: note, appState: self)
    controllers[note.persistentModelID] = controller
    note.isOpen = true
    save()
    controller.show()
  }

  /// Fully closes and forgets a note's window (used on delete or explicit dock).
  func closeWindow(for note: Note) {
    guard let controller = controllers.removeValue(forKey: note.persistentModelID) else { return }
    controller.orderOut()
    note.isOpen = false
    save()
  }

  /// Slides the note's window back into the left edge, then closes it.
  func dockWindow(for note: Note) {
    guard let controller = controllers[note.persistentModelID] else { return }
    controller.animateDock { [weak self] in
      self?.closeWindow(for: note)
    }
  }

  func toggleWindow(for note: Note) {
    if controllers[note.persistentModelID] != nil {
      dockWindow(for: note)
    } else {
      openWindow(for: note)
    }
  }
}

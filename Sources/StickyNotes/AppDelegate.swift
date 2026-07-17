import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var appState: AppState!
  private var edge: EdgeHotzoneController!

  func applicationDidFinishLaunching(_ notification: Notification) {
    // SwiftData store. Fall back to in-memory if the on-disk store can't open.
    let container: ModelContainer
    do {
      container = try ModelContainer(for: Note.self)
    } catch {
      NSLog("StickyNotes: falling back to in-memory store: \(error)")
      container = try! ModelContainer(
        for: Note.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
    }

    appState = AppState(container: container)
    appState.refresh()

    // Restore any notes that were open last time.
    for note in appState.notes where note.isOpen {
      appState.openWindow(for: note)
    }

    // The always-present edge hot zone that reveals the glass island.
    edge = EdgeHotzoneController(appState: appState)
    edge.install()

    // Accessory apps show no menu bar, but a main menu still routes the
    // standard editing key equivalents (⌘C/⌘V/⌘Z/⌘A) to the focused text view.
    installEditingMenu()
  }

  private func installEditingMenu() {
    let mainMenu = NSMenu()

    // App menu (hosts ⌘Q).
    let appItem = NSMenuItem()
    mainMenu.addItem(appItem)
    let appMenu = NSMenu()
    appItem.submenu = appMenu
    appMenu.addItem(
      withTitle: "Quit Sticky Notes",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")

    // Edit menu (key equivalents only — never displayed).
    let editItem = NSMenuItem()
    mainMenu.addItem(editItem)
    let editMenu = NSMenu(title: "Edit")
    editItem.submenu = editMenu
    editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
    redo.keyEquivalentModifierMask = [.command, .shift]
    editMenu.addItem(NSMenuItem.separator())
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(
      withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

    NSApp.mainMenu = mainMenu
  }
}

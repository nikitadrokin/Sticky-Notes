# Sticky Notes

A macOS sticky-note app that stays out of your way. **No Dock icon, no menu bar** —
it runs as an *accessory* app and lives only as floating Liquid Glass on the desktop.

## The idea

- **Reach the left-center edge of the screen** and a Liquid Glass **island** slides
  out (Dynamic-Island style, but glass, emerging from the bezel).
- The island is your **note tray**: `+` to create, tabs for each note, and Quit.
- **Click a note** → it pops out as a floating glass sticky you can drag anywhere.
- **Shove a note into the left wall** (or hit the ⌄ dock button) → it collapses
  back into the tray.
- Notes persist with **SwiftData** and reopen where you left them.

## How the "invisible app" works

`main.swift` calls `NSApp.setActivationPolicy(.accessory)`. That single line removes
the Dock icon and the menu bar without needing an `Info.plist` / `LSUIElement`, which
is why this ships as a plain **Swift Package executable** — no `.xcodeproj` required.
A hidden main menu is still installed so ⌘C/⌘V/⌘Z/⌘A work inside notes.

## Building / running

Runs via Sweetpad or `swift run`. Requires macOS 26 (Tahoe) for Liquid Glass.

## Source map

| File | Role |
|------|------|
| `main.swift` | Accessory-policy entry point |
| `AppDelegate.swift` | Store setup, restore open notes, editing menu |
| `AppState.swift` | SwiftData store + note/window lifecycle |
| `Note.swift` | `@Model` note + color palette |
| `EdgeHotzoneController.swift` | Invisible left-edge hover strip |
| `IslandController.swift` / `IslandView.swift` | The glass tray that slides out |
| `NoteWindowController.swift` / `NoteView.swift` | Floating glass stickies |
| `TrackingView.swift` / `Support.swift` | Background-safe hover tracking, helpers |

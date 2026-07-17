import AppKit

// Entry point. We run as an "accessory" app: no Dock icon, no menu bar.
// This is what keeps the app invisible except for its floating glass on the desktop.
let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

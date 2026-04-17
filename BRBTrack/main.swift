import AppKit

// Pure-AppKit entry point — bypasses the SwiftUI App lifecycle so that
// NSStatusItem creation in AppDelegate.applicationDidFinishLaunching is
// guaranteed to run on the main thread at the right moment.

let app      = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

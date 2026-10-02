//
//  SettingsWindow.swift
//  Glimpse
//
//  Opening and focusing the SwiftUI Settings scene from anywhere in the app.
//

import AppKit
import SwiftUI

/// Central access to the `Settings` scene's window.
///
/// Glimpse is `LSUIElement`, so there is no Dock icon and no Cmd+Tab entry. If the menu bar
/// item is pushed off-screen by other menu bar apps (easy on a notched Mac), the app would
/// otherwise be completely unreachable — no way to open Settings, un-pause, or even quit.
/// `AppDelegate` uses this to make relaunching the app surface Settings.
@MainActor
enum SettingsWindow {
    /// SwiftUI's identifier for the `Settings` scene window.
    ///
    /// Match on this, never on the title: SwiftUI names the window "<App Name> Settings"
    /// ("Glimpse Settings"), and that string is localized, so a `title == "Settings"` check
    /// silently never matches. The identifier is stable and locale-independent.
    private static let identifier = "com_apple_SwiftUI_Settings_window"

    /// The SwiftUI `openSettings` action, handed over by a long-lived View.
    ///
    /// `openSettings` is an `@Environment` action and cannot be reached from an
    /// `NSApplicationDelegate`. The usual AppKit escape hatches do not work either —
    /// `showSettingsWindow:` reports success and opens nothing, and `showPreferencesWindow:`
    /// is not handled at all (both measured on macOS 26). So a View has to donate it.
    /// `MenuBarLabel` does, because the MenuBarExtra *label* lives for the whole app
    /// lifetime, unlike the popover content which only exists while the popover is open.
    static var openAction: (() -> Void)?

    /// The live Settings window, if SwiftUI has created it.
    static var window: NSWindow? {
        NSApp.windows.first { $0.identifier?.rawValue == identifier }
            ?? NSApp.windows.first { $0.title.hasSuffix("Settings") && $0.canBecomeKey }
    }

    /// Open Settings if needed, then pull it to the front.
    static func show() {
        openAction?()
        raise()
    }

    /// Bring the app forward and make the Settings window key.
    ///
    /// Callers that already hold their own `openSettings` action should call this straight
    /// after invoking it.
    static func raise() {
        // Deferred by one runloop turn: activating synchronously from inside
        // `applicationShouldHandleReopen` does not stick, and the window may have just been
        // created. Deferring makes both paths behave.
        DispatchQueue.main.async {
            // `activate(ignoringOtherApps:)` is deprecated since macOS 14, but measured on
            // macOS 26 it is the only variant that actually activates an LSUIElement app —
            // plain `NSApp.activate()` and `NSRunningApplication.current.activate(options:)`
            // both leave `NSApp.isActive` false. Keep it until a replacement works for
            // accessory apps.
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
        }
    }
}

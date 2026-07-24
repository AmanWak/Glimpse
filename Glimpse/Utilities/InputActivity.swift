//
//  InputActivity.swift
//  Glimpse
//
//  System-wide input timing queries used to hold breaks while typing.
//

import Foundation
import CoreGraphics

enum InputActivity {
    /// Seconds since the user last pressed any key, system-wide.
    /// CGEventSource only exposes timing — no keystroke content — so this
    /// requires no Accessibility or Input Monitoring permission.
    static func secondsSinceLastKeyPress() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .keyDown)
    }
}

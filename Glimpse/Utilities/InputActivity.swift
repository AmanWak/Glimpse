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

    // MARK: - Hold-while-typing decisions

    /// Whether a due break should wait because the user is mid-keystroke.
    static func shouldHoldBreak(holdEnabled: Bool, secondsSinceKeyPress: TimeInterval) -> Bool {
        holdEnabled && secondsSinceKeyPress < Constants.typingPauseThreshold
    }

    /// Whether a held break should start now: typing has paused, or the hold cap is reached.
    static func shouldEndHold(now: Date, deadline: Date, secondsSinceKeyPress: TimeInterval) -> Bool {
        now >= deadline || secondsSinceKeyPress >= Constants.typingPauseThreshold
    }
}

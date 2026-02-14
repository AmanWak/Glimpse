//
//  Constants.swift
//  Glimpse
//
//  Timing constants and defaults for the 20-20-20 rule.
//

import Foundation

enum Constants {
    /// Work interval before a break (20 minutes in seconds)
    static let workDuration: TimeInterval = 1200

    /// Break duration (20 seconds)
    static let breakDuration: TimeInterval = 20

    /// Default overlay opacity (0.0-1.0)
    static let defaultOverlayOpacity: Double = 0.85

    /// Minimum overlay opacity
    static let minOverlayOpacity: Double = 0.5

    /// Maximum overlay opacity
    static let maxOverlayOpacity: Double = 1.0

    /// Default overlay color (hex)
    static let defaultOverlayColorHex: String = "5BDDAF"

    /// Timer tick interval
    static let timerTickInterval: TimeInterval = 1.0

    /// UserDefaults keys
    enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let breakStyle = "breakStyle"
        static let overlayOpacity = "overlayOpacity"
        static let overlayColorHex = "overlayColorHex"
        static let skipConfirmation = "skipConfirmation"
        static let breakStreak = "breakStreak"
    }
}

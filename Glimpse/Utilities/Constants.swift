//
//  Constants.swift
//  Glimpse
//
//  Timing constants and defaults for the 20-20-20 rule.
//

import Foundation

enum Constants {
    /// Default work interval before a break (20 minutes in seconds)
    static let defaultWorkDuration: TimeInterval = 1200

    /// Default break duration (20 seconds)
    static let defaultBreakDuration: TimeInterval = 20

    /// Minimum work duration (5 minutes)
    static let minWorkDuration: TimeInterval = 300

    /// Maximum work duration (60 minutes)
    static let maxWorkDuration: TimeInterval = 3600

    /// Minimum break duration (10 seconds)
    static let minBreakDuration: TimeInterval = 10

    /// Maximum break duration (120 seconds)
    static let maxBreakDuration: TimeInterval = 120

    /// Work duration presets in seconds
    static let workDurationPresets: [TimeInterval] = [300, 600, 900, 1200, 1500, 1800, 2700, 3600]

    /// Break duration presets in seconds
    static let breakDurationPresets: [TimeInterval] = [10, 15, 20, 30, 45, 60, 90, 120]

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

    /// Heads-up notification lead time before break (seconds)
    static let headsUpLeadTime: TimeInterval = 30

    /// Minimum sleep duration before resetting the work timer on wake (seconds)
    static let sleepResetThreshold: TimeInterval = 60

    /// Quiet gap in typing required before a held break may start (seconds)
    static let typingPauseThreshold: TimeInterval = 1.5

    /// Maximum time a break is held while the user keeps typing (seconds)
    static let maxBreakHold: TimeInterval = 60

    /// Default break notes shown during overlay breaks
    static let defaultBreakNotes: [String] = [
        "Sit up straight",
        "Drink some water",
        "Relax your shoulders",
        "Unclench your jaw",
        "Take a deep breath",
    ]

    /// Preset meeting apps offered in the auto-pause "Add App" menu
    static let watchableAppPresets: [(name: String, bundleID: String)] = [
        ("Zoom", "us.zoom.xos"),
        ("Microsoft Teams", "com.microsoft.teams2"),
        ("Webex", "com.webex.meetingmanager"),
        ("Slack", "com.tinyspeck.slackmacgap"),
        ("FaceTime", "com.apple.FaceTime"),
        ("Discord", "com.hnc.Discord"),
    ]

    /// Preset game launchers offered in the auto-pause "Add App" menu
    static let watchableGamePresets: [(name: String, bundleID: String)] = [
        ("Steam", "com.valvesoftware.steam"),
        ("Epic Games", "com.epicgames.EpicGamesLauncher"),
        ("Battle.net", "net.battle.app"),
        ("GOG Galaxy", "com.gogcom.GOGGalaxy"),
        ("Itch.io", "io.itch.app"),
        ("Xbox", "com.microsoft.GamingApp"),
    ]

    /// All auto-pause presets (meetings + game launchers) for name lookup
    static var allWatchablePresets: [(name: String, bundleID: String)] {
        watchableAppPresets + watchableGamePresets
    }

    /// UserDefaults keys
    enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let breakStyle = "breakStyle"
        static let overlayOpacity = "overlayOpacity"
        static let overlayColorHex = "overlayColorHex"
        static let skipConfirmation = "skipConfirmation"
        static let breakStreak = "breakStreak"
        static let headsUpNotification = "headsUpNotification"
        static let playSoundOnBreakEnd = "playSoundOnBreakEnd"
        static let appAwarePauseEnabled = "appAwarePauseEnabled"
        static let watchedBundleIDs = "watchedBundleIDs"
        // Legacy keys — games merged into the unified watched list; kept for one-time migration
        static let gamePauseEnabled = "gamePauseEnabled"
        static let watchedGameBundleIDs = "watchedGameBundleIDs"
        static let controllerPauseEnabled = "controllerPauseEnabled"
        static let gameModePauseEnabled = "gameModePauseEnabled"
        static let showMenuBarTimer = "showMenuBarTimer"
        static let holdBreakWhileTyping = "holdBreakWhileTyping"
        static let workDuration = "workDuration"
        static let breakDuration = "breakDuration"
        static let breakNotesEnabled = "breakNotesEnabled"
        static let breakNotes = "breakNotes"
    }
}

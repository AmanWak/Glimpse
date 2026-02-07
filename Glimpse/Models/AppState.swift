//
//  AppState.swift
//  Glimpse
//
//  Central observable state for the app.
//

import SwiftUI

/// Break display style
enum BreakStyle: String, CaseIterable, Identifiable {
    case overlay = "Full Screen Overlay"
    case notification = "Notification Only"

    var id: String { rawValue }
}

/// Current app mode
enum AppMode: Equatable {
    case working
    case onBreak
    case paused
}

@MainActor
@Observable
final class AppState {
    // MARK: - Settings (persisted via @AppStorage in views)

    /// Launch app at login
    var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.Keys.launchAtLogin) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.Keys.launchAtLogin) }
    }

    /// Break display style
    var breakStyle: BreakStyle {
        get {
            let raw = UserDefaults.standard.string(forKey: Constants.Keys.breakStyle) ?? BreakStyle.overlay.rawValue
            return BreakStyle(rawValue: raw) ?? .overlay
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Constants.Keys.breakStyle) }
    }

    /// Overlay opacity (0.5-1.0)
    var overlayOpacity: Double {
        get { UserDefaults.standard.double(forKey: Constants.Keys.overlayOpacity).clamped(to: Constants.minOverlayOpacity...Constants.maxOverlayOpacity) }
        set { UserDefaults.standard.set(newValue.clamped(to: Constants.minOverlayOpacity...Constants.maxOverlayOpacity), forKey: Constants.Keys.overlayOpacity) }
    }

    /// Overlay color as hex string
    var overlayColorHex: String {
        get { UserDefaults.standard.string(forKey: Constants.Keys.overlayColorHex) ?? Constants.defaultOverlayColorHex }
        set { UserDefaults.standard.set(newValue, forKey: Constants.Keys.overlayColorHex) }
    }

    /// Require confirmation before skipping
    var skipConfirmation: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.Keys.skipConfirmation) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.Keys.skipConfirmation) }
    }

    // MARK: - Runtime State

    /// Current app mode
    var mode: AppMode = .working

    /// Seconds remaining in current timer
    var secondsRemaining: TimeInterval = Constants.workDuration

    /// Current break message
    var currentMessage: String = ""

    /// Break streak tracking
    var streak: BreakStreak = BreakStreak.load()

    /// Whether overlay is currently shown
    var isOverlayShowing: Bool = false

    // MARK: - Computed Properties

    /// Formatted time remaining string (MM:SS or SS)
    var timeRemainingFormatted: String {
        let seconds = Int(secondsRemaining)
        if seconds >= 60 {
            let mins = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", mins, secs)
        }
        return "\(seconds)"
    }

    /// Status text for menu bar
    var statusText: String {
        switch mode {
        case .working:
            return "Next break in \(timeRemainingFormatted)"
        case .onBreak:
            return "Break: \(timeRemainingFormatted)s"
        case .paused:
            return "Paused"
        }
    }

    /// Menu bar icon name
    var menuBarIcon: String {
        switch mode {
        case .working:
            return "eye"
        case .onBreak:
            return "eye.fill"
        case .paused:
            return "pause.circle"
        }
    }

    // MARK: - Methods

    /// Initialize with default opacity if not set
    init() {
        if UserDefaults.standard.object(forKey: Constants.Keys.overlayOpacity) == nil {
            UserDefaults.standard.set(Constants.defaultOverlayOpacity, forKey: Constants.Keys.overlayOpacity)
        }
    }

    /// Start a new work period
    func startWorkPeriod() {
        mode = .working
        secondsRemaining = Constants.workDuration
    }

    /// Start a break
    func startBreak() {
        mode = .onBreak
        secondsRemaining = Constants.breakDuration
        currentMessage = Messages.random()
    }

    /// Complete a break (not skipped)
    func completeBreak() {
        streak.recordCompletion()
        streak.save()
        startWorkPeriod()
    }

    /// Skip the current break
    func skipBreak() {
        streak.recordSkip()
        streak.save()
        startWorkPeriod()
    }

    /// Pause the timer
    func pause() {
        mode = .paused
    }

    /// Resume from pause
    func resume() {
        mode = .working
    }

    /// Save current state
    func saveState() {
        streak.save()
    }
}

// MARK: - Helpers

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

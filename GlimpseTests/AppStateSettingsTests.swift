//
//  AppStateSettingsTests.swift
//  GlimpseTests
//
//  Tests for AppState persisted settings and edge cases.
//

import Foundation
import Testing
@testable import Glimpse

@MainActor
@Suite(.serialized)
struct AppStateSettingsTests {
    private let keysToReset: [String] = [
        Constants.Keys.launchAtLogin,
        Constants.Keys.breakStyle,
        Constants.Keys.overlayOpacity,
        Constants.Keys.overlayColorHex,
        Constants.Keys.skipConfirmation,
        Constants.Keys.breakStreak,
        Constants.Keys.headsUpNotification,
        Constants.Keys.playSoundOnBreakEnd,
        // Note: appAwarePauseEnabled/watchedBundleIDs deliberately absent — they
        // belong to AppWatcher, and AppWatcherPersistenceTests runs in parallel
        // with this suite on the same UserDefaults.
        Constants.Keys.showMenuBarTimer,
        Constants.Keys.holdBreakWhileTyping,
        Constants.Keys.workDuration,
        Constants.Keys.breakDuration,
        Constants.Keys.breakNotesEnabled,
        Constants.Keys.breakNotes,
    ]

    private func resetDefaults() {
        for key in keysToReset {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test func defaultsMatchExpectedFirstRunBehavior() {
        resetDefaults()
        let state = AppState()

        #expect(state.launchAtLogin == false)
        #expect(state.breakStyle == .overlay)
        #expect(state.overlayOpacity == Constants.defaultOverlayOpacity)
        #expect(state.overlayColorHex == Constants.defaultOverlayColorHex)
        #expect(state.headsUpNotification == true)
        #expect(state.skipConfirmation == false)
        #expect(state.playSoundOnBreakEnd == true)
        #expect(state.showMenuBarTimer == true)
        #expect(state.holdBreakWhileTyping == true)
        #expect(state.breakNotesEnabled == true)
        #expect(state.breakNotes == Constants.defaultBreakNotes)

        resetDefaults()
    }

    @Test func holdBreakWhileTypingPersistsWhenDisabled() {
        resetDefaults()
        let state = AppState()

        state.holdBreakWhileTyping = false

        #expect(state.holdBreakWhileTyping == false)
        #expect(AppState().holdBreakWhileTyping == false)

        resetDefaults()
    }

    @Test func overlayOpacityClampsLowAndHighValues() {
        resetDefaults()
        let state = AppState()

        state.overlayOpacity = -10
        #expect(state.overlayOpacity == Constants.minOverlayOpacity)

        state.overlayOpacity = 10
        #expect(state.overlayOpacity == Constants.maxOverlayOpacity)

        resetDefaults()
    }

    @Test func invalidPersistedBreakStyleFallsBackToOverlay() {
        resetDefaults()
        UserDefaults.standard.set("Not A Real Break Style", forKey: Constants.Keys.breakStyle)

        let state = AppState()

        #expect(state.breakStyle == .overlay)

        resetDefaults()
    }

    @Test func nonPositiveDurationsFallBackToDefaults() {
        resetDefaults()
        UserDefaults.standard.set(0, forKey: Constants.Keys.workDuration)
        UserDefaults.standard.set(-5, forKey: Constants.Keys.breakDuration)

        let state = AppState()

        #expect(state.workDuration == Constants.defaultWorkDuration)
        #expect(state.breakDuration == Constants.defaultBreakDuration)

        resetDefaults()
    }

    @Test func customDurationsDriveNewWorkAndBreakPeriods() {
        resetDefaults()
        let state = AppState()
        state.workDuration = 900
        state.breakDuration = 45

        state.startWorkPeriod()
        #expect(state.secondsRemaining == 900)

        state.startBreak()
        #expect(state.secondsRemaining == 45)

        resetDefaults()
    }

    @Test func resumeRestoresPausedBreakMode() {
        resetDefaults()
        let state = AppState()

        state.startBreak()
        state.pause()
        state.resume()

        #expect(state.mode == .onBreak)

        resetDefaults()
    }

    @Test func completingBreakResetsConsecutiveSkips() {
        resetDefaults()
        let state = AppState()

        state.startBreak()
        state.skipBreak()
        #expect(state.streak.consecutiveSkips == 1)

        state.startBreak()
        state.completeBreak()

        #expect(state.streak.completedToday == 1)
        #expect(state.streak.consecutiveSkips == 0)

        resetDefaults()
    }

    @Test func malformedBreakNotesFallBackToDefaults() {
        resetDefaults()
        UserDefaults.standard.set(Data("not-json".utf8), forKey: Constants.Keys.breakNotes)

        let state = AppState()

        #expect(state.breakNotes == Constants.defaultBreakNotes)

        resetDefaults()
    }

    @Test func corruptedPersistedStreakFallsBackToFreshStreak() {
        resetDefaults()
        UserDefaults.standard.set(Data("not-json".utf8), forKey: Constants.Keys.breakStreak)

        let streak = BreakStreak.load()

        #expect(streak.completedToday == 0)
        #expect(streak.consecutiveSkips == 0)

        resetDefaults()
    }
}

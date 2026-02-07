//
//  AppStateTests.swift
//  GlimpseTests
//
//  Tests for central app state.
//

import Testing
import Foundation
@testable import Glimpse

@MainActor
struct AppStateTests {

    @Test func initialModeIsWorking() {
        let state = AppState()
        #expect(state.mode == .working)
    }

    @Test func initialSecondsIsWorkDuration() {
        let state = AppState()
        #expect(state.secondsRemaining == Constants.workDuration)
    }

    @Test func startWorkPeriodSetsCorrectState() {
        let state = AppState()
        state.startBreak() // First change state
        state.startWorkPeriod()

        #expect(state.mode == .working)
        #expect(state.secondsRemaining == Constants.workDuration)
    }

    @Test func startBreakSetsCorrectState() {
        let state = AppState()
        state.startBreak()

        #expect(state.mode == .onBreak)
        #expect(state.secondsRemaining == Constants.breakDuration)
        #expect(!state.currentMessage.isEmpty)
    }

    @Test func pauseSetsMode() {
        let state = AppState()
        state.pause()

        #expect(state.mode == .paused)
    }

    @Test func resumeSetsMode() {
        let state = AppState()
        state.pause()
        state.resume()

        #expect(state.mode == .working)
    }

    @Test func completeBreakIncrementsStreak() {
        let state = AppState()
        let initialCompleted = state.streak.completedToday

        state.startBreak()
        state.completeBreak()

        #expect(state.streak.completedToday == initialCompleted + 1)
        #expect(state.mode == .working)
    }

    @Test func skipBreakIncrementsConsecutiveSkips() {
        let state = AppState()
        let initialSkips = state.streak.consecutiveSkips

        state.startBreak()
        state.skipBreak()

        #expect(state.streak.consecutiveSkips == initialSkips + 1)
        #expect(state.mode == .working)
    }

    @Test func timeRemainingFormattedForMinutes() {
        let state = AppState()
        state.secondsRemaining = 125 // 2:05

        #expect(state.timeRemainingFormatted == "2:05")
    }

    @Test func timeRemainingFormattedForSeconds() {
        let state = AppState()
        state.secondsRemaining = 45

        #expect(state.timeRemainingFormatted == "45")
    }

    @Test func statusTextDuringWork() {
        let state = AppState()
        state.mode = .working
        state.secondsRemaining = 600 // 10:00

        #expect(state.statusText == "Next break in 10:00")
    }

    @Test func statusTextDuringBreak() {
        let state = AppState()
        state.mode = .onBreak
        state.secondsRemaining = 15

        #expect(state.statusText == "Break: 15s")
    }

    @Test func statusTextWhenPaused() {
        let state = AppState()
        state.mode = .paused

        #expect(state.statusText == "Paused")
    }

    @Test func menuBarIconForWorking() {
        let state = AppState()
        state.mode = .working

        #expect(state.menuBarIcon == "eye")
    }

    @Test func menuBarIconForBreak() {
        let state = AppState()
        state.mode = .onBreak

        #expect(state.menuBarIcon == "eye.fill")
    }

    @Test func menuBarIconForPaused() {
        let state = AppState()
        state.mode = .paused

        #expect(state.menuBarIcon == "pause.circle")
    }
}

//
//  TimerManagerTests.swift
//  GlimpseTests
//
//  Tests for timer management.
//

import Testing
import Foundation
@testable import Glimpse

struct TimerManagerTests {

    @Test func initialStateIsNotBreak() {
        let manager = TimerManager()
        #expect(!manager.isInBreak)
    }

    @Test func startWorkTimerSetsCorrectDuration() {
        let manager = TimerManager()
        manager.startWorkTimer()

        #expect(manager.currentRemainingTime == Constants.defaultWorkDuration)
        #expect(!manager.isInBreak)

        manager.stop()
    }

    @Test func startBreakTimerSetsCorrectDuration() {
        let manager = TimerManager()
        manager.startBreakTimer()

        #expect(manager.currentRemainingTime == Constants.defaultBreakDuration)
        #expect(manager.isInBreak)

        manager.stop()
    }

    @Test func pauseStopsTimer() async {
        let manager = TimerManager()
        manager.startWorkTimer()

        let initialTime = manager.currentRemainingTime
        manager.pause()

        // Wait a bit and verify time hasn't changed
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        #expect(manager.currentRemainingTime == initialTime)

        manager.stop()
    }

    @Test func resumeRestoresTimer() {
        let manager = TimerManager()
        let remainingTime: TimeInterval = 500
        manager.resume(remainingTime: remainingTime, isBreak: false)

        #expect(manager.currentRemainingTime == remainingTime)
        #expect(!manager.isInBreak)

        manager.stop()
    }

    @Test func resumeAsBreak() {
        let manager = TimerManager()
        let remainingTime: TimeInterval = 15
        manager.resume(remainingTime: remainingTime, isBreak: true)

        #expect(manager.currentRemainingTime == remainingTime)
        #expect(manager.isInBreak)

        manager.stop()
    }

    @Test func stopResetsState() {
        let manager = TimerManager()
        manager.startBreakTimer()
        manager.stop()

        #expect(manager.currentRemainingTime == Constants.defaultWorkDuration)
        #expect(!manager.isInBreak)
    }

    @Test func onTickCallbackFires() async throws {
        let manager = TimerManager()
        var tickCount = 0

        manager.onTick = { _ in
            tickCount += 1
        }

        // Use a very short duration for testing
        manager.resume(remainingTime: 2, isBreak: false)

        // Wait for at least one tick
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        manager.stop()

        #expect(tickCount >= 1)
    }

    @Test func onWorkCompleteCallbackFires() async throws {
        let manager = TimerManager()
        var workCompleted = false

        manager.onWorkComplete = {
            workCompleted = true
        }

        // Start with very short remaining time
        manager.resume(remainingTime: 1.1, isBreak: false)

        // Wait for completion (need extra time for timer scheduling)
        try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds

        #expect(workCompleted)
    }

    @Test func startWorkTimerWithCustomDuration() {
        let manager = TimerManager()
        manager.startWorkTimer(duration: 900) // 15 min

        #expect(manager.currentRemainingTime == 900)
        #expect(!manager.isInBreak)

        manager.stop()
    }

    @Test func startBreakTimerWithCustomDuration() {
        let manager = TimerManager()
        manager.startBreakTimer(duration: 45) // 45 sec

        #expect(manager.currentRemainingTime == 45)
        #expect(manager.isInBreak)

        manager.stop()
    }

    @Test func startingBreakTimerReplacesRunningWorkTimer() async throws {
        let manager = TimerManager()
        var workCompleted = false
        var breakCompleted = false

        manager.onWorkComplete = {
            workCompleted = true
        }
        manager.onBreakComplete = {
            breakCompleted = true
        }

        manager.startWorkTimer(duration: 1.1)
        manager.startBreakTimer(duration: 2.5)

        try await Task.sleep(nanoseconds: 1_500_000_000)

        #expect(!workCompleted)
        #expect(!breakCompleted)
        #expect(manager.isInBreak)
        #expect(manager.currentRemainingTime > 0)

        manager.stop()
    }

    @Test func stopPreventsCompletionCallback() async throws {
        let manager = TimerManager()
        var workCompleted = false
        manager.onWorkComplete = {
            workCompleted = true
        }

        manager.resume(remainingTime: 1.1, isBreak: false)
        manager.stop()

        try await Task.sleep(nanoseconds: 1_500_000_000)

        #expect(!workCompleted)
        #expect(manager.currentRemainingTime == Constants.defaultWorkDuration)
        #expect(!manager.isInBreak)
    }

    @Test func onBreakCompleteCallbackFires() async throws {
        let manager = TimerManager()
        var breakCompleted = false

        manager.onBreakComplete = {
            breakCompleted = true
        }

        // Start break with very short remaining time
        manager.resume(remainingTime: 1.1, isBreak: true)

        // Wait for completion (need extra time for timer scheduling)
        try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds

        #expect(breakCompleted)
    }
}

//
//  SleepWakeHandlerTests.swift
//  GlimpseTests
//
//  Tests for the reset-vs-resume decision after the Mac wakes.
//

import Testing
import Foundation
@testable import Glimpse

struct SleepWakeHandlerTests {

    @Test func shortSleepResumesTheTimer() {
        #expect(!SleepWakeHandler.shouldResetTimer(afterSleepOf: 0))
        #expect(!SleepWakeHandler.shouldResetTimer(afterSleepOf: Constants.sleepResetThreshold - 1))
    }

    @Test func sleepAtThresholdResetsTheTimer() {
        #expect(SleepWakeHandler.shouldResetTimer(afterSleepOf: Constants.sleepResetThreshold))
    }

    @Test func longSleepResetsTheTimer() {
        #expect(SleepWakeHandler.shouldResetTimer(afterSleepOf: 8 * 3600))
    }

    @Test func thresholdIsShorterThanShortestWorkInterval() {
        // Otherwise a sleep could outlast a whole work period and still resume into a
        // stale break.
        let shortestWork = Constants.workDurationPresets.min() ?? Constants.defaultWorkDuration
        #expect(Constants.sleepResetThreshold > 0)
        #expect(Constants.sleepResetThreshold < shortestWork)
    }
}

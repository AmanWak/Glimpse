//
//  InputActivityTests.swift
//  GlimpseTests
//
//  Tests for the hold-break-while-typing decisions.
//

import Testing
import Foundation
@testable import Glimpse

struct InputActivityTests {

    private let threshold = Constants.typingPauseThreshold

    // MARK: - shouldHoldBreak

    @Test func holdsWhileActivelyTyping() {
        #expect(InputActivity.shouldHoldBreak(holdEnabled: true, secondsSinceKeyPress: 0))
        #expect(InputActivity.shouldHoldBreak(holdEnabled: true, secondsSinceKeyPress: threshold - 0.01))
    }

    @Test func doesNotHoldOnceTypingHasPaused() {
        #expect(!InputActivity.shouldHoldBreak(holdEnabled: true, secondsSinceKeyPress: threshold))
        #expect(!InputActivity.shouldHoldBreak(holdEnabled: true, secondsSinceKeyPress: 300))
    }

    @Test func neverHoldsWhenSettingIsOff() {
        #expect(!InputActivity.shouldHoldBreak(holdEnabled: false, secondsSinceKeyPress: 0))
        #expect(!InputActivity.shouldHoldBreak(holdEnabled: false, secondsSinceKeyPress: 300))
    }

    // MARK: - shouldEndHold

    @Test func keepsHoldingWhileTypingBeforeDeadline() {
        let now = Date()
        #expect(!InputActivity.shouldEndHold(
            now: now,
            deadline: now.addingTimeInterval(30),
            secondsSinceKeyPress: 0.2
        ))
    }

    @Test func endsHoldWhenTypingPauses() {
        let now = Date()
        #expect(InputActivity.shouldEndHold(
            now: now,
            deadline: now.addingTimeInterval(30),
            secondsSinceKeyPress: threshold
        ))
    }

    @Test func endsHoldAtDeadlineEvenIfStillTyping() {
        let now = Date()
        #expect(InputActivity.shouldEndHold(now: now, deadline: now, secondsSinceKeyPress: 0))
        #expect(InputActivity.shouldEndHold(
            now: now,
            deadline: now.addingTimeInterval(-1),
            secondsSinceKeyPress: 0
        ))
    }

    // MARK: - Constants and live query

    @Test func holdCapIsLongerThanTypingPause() {
        #expect(Constants.typingPauseThreshold > 0)
        #expect(Constants.maxBreakHold > Constants.typingPauseThreshold)
    }

    @Test func liveKeyPressQueryIsNonNegative() {
        #expect(InputActivity.secondsSinceLastKeyPress() >= 0)
    }
}

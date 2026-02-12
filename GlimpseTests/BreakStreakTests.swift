//
//  BreakStreakTests.swift
//  GlimpseTests
//
//  Tests for break streak tracking.
//

import Testing
import Foundation
@testable import Glimpse

struct BreakStreakTests {

    @Test func initialStateIsZero() {
        let streak = BreakStreak()
        #expect(streak.completedToday == 0)
        #expect(streak.consecutiveSkips == 0)
    }

    @Test func recordCompletionIncrementsCount() {
        var streak = BreakStreak()
        streak.recordCompletion()
        #expect(streak.completedToday == 1)

        streak.recordCompletion()
        #expect(streak.completedToday == 2)
    }

    @Test func recordCompletionResetsSkips() {
        var streak = BreakStreak()
        streak.recordSkip()
        streak.recordSkip()
        #expect(streak.consecutiveSkips == 2)

        streak.recordCompletion()
        #expect(streak.consecutiveSkips == 0)
    }

    @Test func recordSkipIncrementsConsecutiveSkips() {
        var streak = BreakStreak()
        streak.recordSkip()
        #expect(streak.consecutiveSkips == 1)

        streak.recordSkip()
        #expect(streak.consecutiveSkips == 2)
    }

    @Test func recordSkipDoesNotIncrementCompleted() {
        var streak = BreakStreak()
        streak.recordSkip()
        #expect(streak.completedToday == 0)
    }

    @Test func resetIfNewDayResetsCounters() {
        // Create a streak with yesterday's date
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var streak = BreakStreak(completedToday: 5, consecutiveSkips: 2, lastActivityDate: yesterday)

        streak.resetIfNewDay()

        #expect(streak.completedToday == 0)
        #expect(streak.consecutiveSkips == 0)
    }

    @Test func resetIfNewDayDoesNotResetToday() {
        var streak = BreakStreak(completedToday: 5, consecutiveSkips: 2, lastActivityDate: Date())

        streak.resetIfNewDay()

        #expect(streak.completedToday == 5)
        #expect(streak.consecutiveSkips == 2)
    }

    @Test func recordCompletionAutoResetsOnNewDay() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var streak = BreakStreak(completedToday: 5, consecutiveSkips: 2, lastActivityDate: yesterday)

        streak.recordCompletion()

        // Should have reset to 0, then incremented to 1
        #expect(streak.completedToday == 1)
        #expect(streak.consecutiveSkips == 0)
    }

    @Test func equatableWorks() {
        let date = Date()
        let streak1 = BreakStreak(completedToday: 3, consecutiveSkips: 1, lastActivityDate: date)
        let streak2 = BreakStreak(completedToday: 3, consecutiveSkips: 1, lastActivityDate: date)
        let streak3 = BreakStreak(completedToday: 4, consecutiveSkips: 1, lastActivityDate: date)

        #expect(streak1 == streak2)
        #expect(streak1 != streak3)
    }

    @Test func encodingAndDecodingWorks() throws {
        let original = BreakStreak(completedToday: 7, consecutiveSkips: 2, lastActivityDate: Date())

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BreakStreak.self, from: data)

        #expect(decoded.completedToday == original.completedToday)
        #expect(decoded.consecutiveSkips == original.consecutiveSkips)
    }
}

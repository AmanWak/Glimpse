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

    // MARK: - Daily history

    @Test func recordCompletionWritesTodayIntoHistory() {
        var streak = BreakStreak()
        streak.recordCompletion()
        streak.recordCompletion()

        let todayKey = BreakStreak.dayKey(for: Date())
        #expect(streak.dailyHistory[todayKey] == 2)
    }

    @Test func recordSkipDoesNotTouchHistory() {
        var streak = BreakStreak()
        streak.recordSkip()

        #expect(streak.dailyHistory.isEmpty)
    }

    @Test func decodingLegacyDataWithoutHistoryWorks() throws {
        // Encode the pre-history shape by hand
        let legacyJSON = """
        {"completedToday": 3, "consecutiveSkips": 1, "lastActivityDate": 700000000}
        """
        let decoded = try JSONDecoder().decode(BreakStreak.self, from: Data(legacyJSON.utf8))

        #expect(decoded.completedToday == 3)
        #expect(decoded.consecutiveSkips == 1)
        #expect(decoded.dailyHistory.isEmpty)
    }

    @Test func historyRoundTripsThroughCodable() throws {
        var streak = BreakStreak()
        streak.recordCompletion()

        let data = try JSONEncoder().encode(streak)
        let decoded = try JSONDecoder().decode(BreakStreak.self, from: data)

        #expect(decoded.dailyHistory == streak.dailyHistory)
    }

    @Test func pruneRemovesEntriesOlderThanRetention() {
        let calendar = Calendar.current
        let old = calendar.date(byAdding: .day, value: -40, to: Date())!
        let recent = calendar.date(byAdding: .day, value: -3, to: Date())!
        var streak = BreakStreak(dailyHistory: [
            BreakStreak.dayKey(for: old): 5,
            BreakStreak.dayKey(for: recent): 2,
        ])

        streak.pruneHistory()

        #expect(streak.dailyHistory[BreakStreak.dayKey(for: old)] == nil)
        #expect(streak.dailyHistory[BreakStreak.dayKey(for: recent)] == 2)
    }

    @Test func lastSevenDaysReturnsOldestFirstWithGapsAsZero() {
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let streak = BreakStreak(dailyHistory: [
            BreakStreak.dayKey(for: today): 4,
            BreakStreak.dayKey(for: twoDaysAgo): 1,
        ])

        let counts = streak.lastSevenDays(endingOn: today)

        #expect(counts.count == 7)
        #expect(counts[6] == 4)  // today, rightmost
        #expect(counts[4] == 1)  // two days ago
        #expect(counts[5] == 0)  // yesterday, no entry
        #expect(counts[0] == 0)  // six days ago, no entry
    }

    @Test func dayKeyIsStableAndSortable() {
        let calendar = Calendar.current
        let earlier = calendar.date(byAdding: .day, value: -1, to: Date())!

        #expect(BreakStreak.dayKey(for: earlier) < BreakStreak.dayKey(for: Date()))
        #expect(BreakStreak.dayKey(for: Date()).count == 10)
    }
}

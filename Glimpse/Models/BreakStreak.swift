//
//  BreakStreak.swift
//  Glimpse
//
//  Tracks completed breaks for the current day.
//

import Foundation

struct BreakStreak: Codable, Equatable {
    /// Number of completed breaks today
    var completedToday: Int

    /// Number of consecutive skips
    var consecutiveSkips: Int

    /// Date of the last recorded activity (for daily reset)
    var lastActivityDate: Date

    /// Create a new streak (defaults to today)
    init(completedToday: Int = 0, consecutiveSkips: Int = 0, lastActivityDate: Date = Date()) {
        self.completedToday = completedToday
        self.consecutiveSkips = consecutiveSkips
        self.lastActivityDate = lastActivityDate
    }

    /// Check if we need to reset for a new day and do so if needed
    mutating func resetIfNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastActivityDate) {
            completedToday = 0
            consecutiveSkips = 0
            lastActivityDate = Date()
        }
    }

    /// Record a completed break
    mutating func recordCompletion() {
        resetIfNewDay()
        completedToday += 1
        consecutiveSkips = 0
        lastActivityDate = Date()
    }

    /// Record a skipped break
    mutating func recordSkip() {
        resetIfNewDay()
        consecutiveSkips += 1
        lastActivityDate = Date()
    }

    /// Load from UserDefaults
    static func load() -> BreakStreak {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.breakStreak),
              let streak = try? JSONDecoder().decode(BreakStreak.self, from: data) else {
            return BreakStreak()
        }
        var loadedStreak = streak
        loadedStreak.resetIfNewDay()
        return loadedStreak
    }

    /// Save to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Constants.Keys.breakStreak)
        }
    }
}

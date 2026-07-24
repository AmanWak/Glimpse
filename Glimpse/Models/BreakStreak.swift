//
//  BreakStreak.swift
//  Glimpse
//
//  Tracks completed breaks for the current day and a rolling daily history.
//

import Foundation

struct BreakStreak: Codable, Equatable {
    /// Number of completed breaks today
    var completedToday: Int

    /// Number of consecutive skips
    var consecutiveSkips: Int

    /// Date of the last recorded activity (for daily reset)
    var lastActivityDate: Date

    /// Completed-break counts per day, keyed "yyyy-MM-dd", pruned to the last 30 days
    var dailyHistory: [String: Int]

    /// Days of history to retain
    static let historyRetentionDays = 30

    /// Create a new streak (defaults to today)
    init(completedToday: Int = 0, consecutiveSkips: Int = 0, lastActivityDate: Date = Date(),
         dailyHistory: [String: Int] = [:]) {
        self.completedToday = completedToday
        self.consecutiveSkips = consecutiveSkips
        self.lastActivityDate = lastActivityDate
        self.dailyHistory = dailyHistory
    }

    /// Decode with a missing-history fallback so pre-history data still loads
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completedToday = try container.decode(Int.self, forKey: .completedToday)
        consecutiveSkips = try container.decode(Int.self, forKey: .consecutiveSkips)
        lastActivityDate = try container.decode(Date.self, forKey: .lastActivityDate)
        dailyHistory = try container.decodeIfPresent([String: Int].self, forKey: .dailyHistory) ?? [:]
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
        dailyHistory[Self.dayKey(for: lastActivityDate)] = completedToday
        pruneHistory()
    }

    /// Record a skipped break
    mutating func recordSkip() {
        resetIfNewDay()
        consecutiveSkips += 1
        lastActivityDate = Date()
    }

    /// Completed counts for the last 7 days, oldest first (today last)
    func lastSevenDays(endingOn date: Date = Date()) -> [Int] {
        (0..<7).reversed().map { offset in
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: date) else {
                return 0
            }
            return dailyHistory[Self.dayKey(for: day)] ?? 0
        }
    }

    /// Drop history entries older than the retention window
    mutating func pruneHistory() {
        guard let cutoff = Calendar.current.date(
            byAdding: .day, value: -Self.historyRetentionDays, to: Date()) else { return }
        let cutoffKey = Self.dayKey(for: cutoff)
        // "yyyy-MM-dd" keys sort chronologically as strings
        dailyHistory = dailyHistory.filter { $0.key >= cutoffKey }
    }

    /// Stable day key ("yyyy-MM-dd") in the user's current calendar/time zone
    static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Load from UserDefaults
    static func load() -> BreakStreak {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.breakStreak) else {
            return BreakStreak()
        }
        do {
            var streak = try JSONDecoder().decode(BreakStreak.self, from: data)
            streak.resetIfNewDay()
            streak.pruneHistory()
            return streak
        } catch {
            DebugLog.log("BreakStreak: failed to decode — \(error.localizedDescription)")
            return BreakStreak()
        }
    }

    /// Save to UserDefaults
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Constants.Keys.breakStreak)
        } catch {
            DebugLog.log("BreakStreak: failed to encode — \(error.localizedDescription)")
        }
    }
}

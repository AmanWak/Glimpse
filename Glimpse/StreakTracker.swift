//
//  StreakTracker.swift
//  Glimpse
//
//  Tracks daily breaks and consecutive skip counts
//

import Foundation

class StreakTracker: ObservableObject {
    static let shared = StreakTracker()
    
    @Published var breaksToday: Int = 0
    @Published var consecutiveSkips: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let breaksKey = "breaksToday"
    private let lastBreakDateKey = "lastBreakDate"
    private let consecutiveSkipsKey = "consecutiveSkips"
    
    private init() {
        loadData()
        checkIfNewDay()
    }
    
    func incrementBreak() {
        breaksToday += 1
        consecutiveSkips = 0 // Reset skip count on successful break
        saveData()
    }
    
    func recordSkip() {
        consecutiveSkips += 1
        saveData()
    }
    
    var streakEmoji: String {
        guard breaksToday > 0 else { return "" }
        return "🔥 \(breaksToday) break\(breaksToday == 1 ? "" : "s") today"
    }
    
    var shouldShowSkipConfirmation: Bool {
        consecutiveSkips >= 2 && SettingsManager.shared.skipFrictionEnabled
    }
    
    private func loadData() {
        breaksToday = userDefaults.integer(forKey: breaksKey)
        consecutiveSkips = userDefaults.integer(forKey: consecutiveSkipsKey)
    }
    
    private func saveData() {
        userDefaults.set(breaksToday, forKey: breaksKey)
        userDefaults.set(Date(), forKey: lastBreakDateKey)
        userDefaults.set(consecutiveSkips, forKey: consecutiveSkipsKey)
    }
    
    private func checkIfNewDay() {
        guard let lastDate = userDefaults.object(forKey: lastBreakDateKey) as? Date else {
            return
        }
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            // New day - reset counts
            breaksToday = 0
            consecutiveSkips = 0
            saveData()
        }
    }
}

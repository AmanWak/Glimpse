//
//  GlimpseTests.swift
//  GlimpseTests
//
//  Created by Aman Wakankar on 1/30/26.
//

import Testing
@testable import Glimpse

struct GlimpseTests {

    @Test func messageProviderReturnsValidMessages() async throws {
        // Test that message provider returns non-empty messages
        for _ in 0..<100 {
            let message = MessageProvider.randomMessage()
            #expect(!message.isEmpty)
        }
    }
    
    @Test func messageProviderIncludesStandardMessages() async throws {
        // Test that standard messages can be returned
        var foundStandard = false
        for _ in 0..<100 {
            let message = MessageProvider.randomMessage()
            if MessageProvider.standardMessages.contains(message) {
                foundStandard = true
                break
            }
        }
        #expect(foundStandard)
    }
    
    @Test func streakTrackerIncrementWorks() async throws {
        let tracker = StreakTracker.shared
        let initialCount = tracker.breaksToday
        
        tracker.incrementBreak()
        
        #expect(tracker.breaksToday == initialCount + 1)
        #expect(tracker.consecutiveSkips == 0)
    }
    
    @Test func streakTrackerSkipRecording() async throws {
        let tracker = StreakTracker.shared
        let initialSkips = tracker.consecutiveSkips
        
        tracker.recordSkip()
        
        #expect(tracker.consecutiveSkips == initialSkips + 1)
    }
    
    @Test func streakEmojiFormatting() async throws {
        let tracker = StreakTracker.shared
        let emoji = tracker.streakEmoji
        
        if tracker.breaksToday > 0 {
            #expect(emoji.contains("🔥"))
            #expect(emoji.contains("break"))
        } else {
            #expect(emoji.isEmpty)
        }
    }
    
    @Test func settingsManagerDefaults() async throws {
        let settings = SettingsManager.shared
        
        // Test default values are reasonable
        #expect(settings.overlayOpacity >= 0.5 && settings.overlayOpacity <= 0.9)
    }
    
    @Test func timerManagerStartsCorrectly() async throws {
        let timer = TimerManager()
        
        #expect(timer.timeRemaining == TimerManager.workInterval)
        #expect(!timer.isPaused)
        #expect(!timer.isOnBreak)
    }

}

//
//  TimerManager.swift
//  Glimpse
//
//  Manages 20-minute work intervals and 20-second break countdowns
//

import Foundation

protocol TimerManagerDelegate: AnyObject {
    func timerManagerDidTriggerBreak(_ manager: TimerManager)
    func timerManagerDidUpdate(_ manager: TimerManager)
}

class TimerManager: ObservableObject {
    // Constants
    static let workInterval: TimeInterval = 20 * 60 // 20 minutes
    static let breakDuration: TimeInterval = 20 // 20 seconds
    
    // Published properties for UI
    @Published var timeRemaining: TimeInterval = workInterval
    @Published var isPaused: Bool = false
    @Published var isOnBreak: Bool = false
    
    weak var delegate: TimerManagerDelegate?
    
    private var timer: Timer?
    private var pauseDate: Date?
    private var resumeDate: Date?
    private let streakTracker = StreakTracker.shared
    
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func start() {
        guard timer == nil else { return }
        
        GlimpseLogger.log("Starting timer", log: .timer)
        
        timeRemaining = Self.workInterval
        isPaused = false
        isOnBreak = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        delegate?.timerManagerDidUpdate(self)
    }
    
    func stop() {
        GlimpseLogger.log("Stopping timer", log: .timer)
        timer?.invalidate()
        timer = nil
    }
    
    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }
    
    func pause() {
        guard !isPaused else { return }
        GlimpseLogger.log("Timer paused", log: .timer)
        isPaused = true
        pauseDate = Date()
        delegate?.timerManagerDidUpdate(self)
    }
    
    func resume() {
        guard isPaused else { return }
        GlimpseLogger.log("Timer resumed", log: .timer)
        isPaused = false
        pauseDate = nil
        delegate?.timerManagerDidUpdate(self)
    }
    
    func triggerBreakNow() {
        timeRemaining = 0
        tick()
    }
    
    func completeBreak(userSkipped: Bool) {
        if !userSkipped {
            GlimpseLogger.log("Break completed successfully", log: .timer)
            streakTracker.incrementBreak()
        } else {
            GlimpseLogger.log("Break skipped by user", log: .timer, type: .info)
            streakTracker.recordSkip()
        }
        
        // Reset for next work interval
        timeRemaining = Self.workInterval
        isOnBreak = false
        delegate?.timerManagerDidUpdate(self)
    }
    
    private func tick() {
        guard !isPaused else { return }
        
        if isOnBreak {
            // Break countdown
            timeRemaining -= 1
            
            if timeRemaining <= 0 {
                // Break completed
                completeBreak(userSkipped: false)
            }
        } else {
            // Work interval countdown
            timeRemaining -= 1
            
            if timeRemaining <= 0 {
                // Trigger break
                GlimpseLogger.log("Work interval complete - triggering break", log: .timer)
                isOnBreak = true
                timeRemaining = Self.breakDuration
                delegate?.timerManagerDidTriggerBreak(self)
            }
        }
        
        delegate?.timerManagerDidUpdate(self)
    }
}

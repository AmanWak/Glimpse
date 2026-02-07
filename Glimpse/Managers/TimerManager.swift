//
//  TimerManager.swift
//  Glimpse
//
//  Manages work and break timers with callbacks.
//

import Foundation

final class TimerManager {
    /// Callback fired every second with remaining time
    var onTick: ((TimeInterval) -> Void)?

    /// Callback fired when work period completes (time for break)
    var onWorkComplete: (() -> Void)?

    /// Callback fired when break completes
    var onBreakComplete: (() -> Void)?

    private var timer: Timer?
    private var remainingTime: TimeInterval = Constants.workDuration
    private var isBreakTimer: Bool = false

    /// Start the work timer
    func startWorkTimer() {
        stopTimer()
        remainingTime = Constants.workDuration
        isBreakTimer = false
        startTimer()
    }

    /// Start the break timer
    func startBreakTimer() {
        stopTimer()
        remainingTime = Constants.breakDuration
        isBreakTimer = true
        startTimer()
    }

    /// Resume timer with remaining time
    func resume(remainingTime: TimeInterval, isBreak: Bool) {
        stopTimer()
        self.remainingTime = remainingTime
        self.isBreakTimer = isBreak
        startTimer()
    }

    /// Pause the timer
    func pause() {
        stopTimer()
    }

    /// Stop and reset the timer
    func stop() {
        stopTimer()
        remainingTime = Constants.workDuration
        isBreakTimer = false
    }

    /// Get current remaining time
    var currentRemainingTime: TimeInterval {
        return remainingTime
    }

    /// Check if currently in break
    var isInBreak: Bool {
        return isBreakTimer
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: Constants.timerTickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Ensure timer fires even when menu is open
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        remainingTime -= Constants.timerTickInterval

        if remainingTime <= 0 {
            remainingTime = 0
            onTick?(remainingTime)
            stopTimer()
            if isBreakTimer {
                onBreakComplete?()
            } else {
                onWorkComplete?()
            }
        } else {
            onTick?(remainingTime)
        }
    }

    deinit {
        stopTimer()
    }
}

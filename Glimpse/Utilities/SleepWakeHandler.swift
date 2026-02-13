//
//  SleepWakeHandler.swift
//  Glimpse
//
//  Handles system sleep/wake events to pause/resume timer.
//

import Foundation
import AppKit

final class SleepWakeHandler {
    /// Called when system is about to sleep
    var onSleep: (() -> Void)?

    /// Called when system wakes up
    var onWake: (() -> Void)?

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    init() {
        DebugLog.log("SleepWakeHandler.init()")
        setupObservers()
    }

    private func setupObservers() {
        let center = NSWorkspace.shared.notificationCenter

        sleepObserver = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DebugLog.log("SleepWakeHandler: system will sleep")
            self?.onSleep?()
        }

        wakeObserver = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DebugLog.log("SleepWakeHandler: system did wake")
            self?.onWake?()
        }
    }

    deinit {
        DebugLog.log("SleepWakeHandler.deinit")
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}

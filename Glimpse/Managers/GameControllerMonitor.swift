//
//  GameControllerMonitor.swift
//  Glimpse
//
//  Pauses Glimpse when a game controller connects, resumes when all disconnect.
//

import GameController

final class GameControllerMonitor {
    /// Called when a controller connects (and feature is enabled)
    var onShouldPause: (() -> Void)?

    /// Called when all controllers disconnect (and feature is enabled)
    var onShouldResume: (() -> Void)?

    /// Whether this monitor triggered the current pause
    private(set) var isPausing = false

    /// When true, ignore controller events until all disconnect once
    private(set) var suppressedUntilClear = false

    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?
    private var defaultsObserver: NSObjectProtocol?

    init() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect, object: nil, queue: .main
        ) { [weak self] _ in self?.evaluate() }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect, object: nil, queue: .main
        ) { [weak self] _ in self?.evaluate() }

        // Re-evaluate immediately when the setting is toggled in Settings
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.evaluate() }
        }
    }

    func evaluate() {
        guard UserDefaults.standard.bool(forKey: Constants.Keys.controllerPauseEnabled) else {
            if isPausing { isPausing = false; onShouldResume?() }
            return
        }
        let connected = !GCController.controllers().isEmpty
        if suppressedUntilClear {
            if !connected { suppressedUntilClear = false }
            return
        }
        if connected && !isPausing {
            isPausing = true
            onShouldPause?()
        } else if !connected && isPausing {
            isPausing = false
            onShouldResume?()
        }
    }

    /// Suppress pausing until all controllers disconnect (used on manual resume)
    func suppressUntilClear() {
        suppressedUntilClear = true
        isPausing = false
    }

    deinit {
        if let obs = connectObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = disconnectObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = defaultsObserver { NotificationCenter.default.removeObserver(obs) }
    }
}

//
//  AppWatcher.swift
//  Glimpse
//
//  Monitors running applications and fires callbacks when watched apps
//  launch or terminate. Uses NSWorkspace notifications (sandbox-safe).
//

import AppKit

final class AppWatcher {
    /// Called when watched apps are detected running (includes all app names)
    var onShouldPause: ((_ appNames: [String]) -> Void)?

    /// Called when no watched apps are running anymore
    var onShouldResume: (() -> Void)?

    /// Whether the watcher triggered the current pause
    private(set) var isPausingForApp = false

    /// When true, ignore watched apps until they all quit once
    private(set) var suppressedUntilClear = false

    private var launchObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    private var defaultsObserver: NSObjectProtocol?

    // MARK: - Injectable config (defaults read from UserDefaults)

    var configEnabled: () -> Bool = {
        UserDefaults.standard.bool(forKey: Constants.Keys.appAwarePauseEnabled)
    }

    var configWatchedIDs: () -> Set<String> = {
        loadWatchedBundleIDs()
    }

    var runningBundleIDs: () -> Set<String> = {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }

    var appNameForBundleID: (String) -> String = { bundleID in
        if let preset = Constants.allWatchablePresets.first(where: { $0.bundleID == bundleID }) {
            return preset.name
        }
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
            return app.localizedName ?? bundleID
        }
        return bundleID
    }

    init() {
        setupObservers()
    }

    /// Convenience init that skips observers (for testing)
    init(skipObservers: Bool) {
        if !skipObservers { setupObservers() }
    }

    // MARK: - Evaluate

    func evaluate() {
        guard configEnabled() else {
            if isPausingForApp {
                isPausingForApp = false
                onShouldResume?()
            }
            suppressedUntilClear = false
            return
        }

        let watched = configWatchedIDs()
        guard !watched.isEmpty else {
            if isPausingForApp {
                isPausingForApp = false
                onShouldResume?()
            }
            suppressedUntilClear = false
            return
        }

        let running = runningBundleIDs()
        let matched = watched.intersection(running)

        if suppressedUntilClear {
            if matched.isEmpty {
                suppressedUntilClear = false
                DebugLog.log("AppWatcher: suppression cleared — all watched apps quit")
            }
            return
        }

        if !matched.isEmpty && !isPausingForApp {
            isPausingForApp = true
            let names = matched.sorted().map { appNameForBundleID($0) }
            DebugLog.log("AppWatcher: \(names.joined(separator: ", ")) detected — firing onShouldPause")
            onShouldPause?(names)
        } else if matched.isEmpty && isPausingForApp {
            isPausingForApp = false
            DebugLog.log("AppWatcher: watched apps gone — firing onShouldResume")
            onShouldResume?()
        }
    }

    /// Suppress pausing until all watched apps quit (used on manual resume)
    func suppressUntilClear() {
        suppressedUntilClear = true
        isPausingForApp = false
    }

    // MARK: - Persistence

    static func loadWatchedBundleIDs() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.watchedBundleIDs),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return ids
    }

    static func saveWatchedBundleIDs(_ ids: Set<String>) {
        let data = try? JSONEncoder().encode(ids)
        UserDefaults.standard.set(data, forKey: Constants.Keys.watchedBundleIDs)
    }

    /// One-time migration: games used to be a separate watched list with its own
    /// enable flag. Fold both into the unified list, then remove the legacy keys.
    static func migrateLegacyGameSettings() {
        let defaults = UserDefaults.standard
        let hadGameIDs = defaults.object(forKey: Constants.Keys.watchedGameBundleIDs) != nil
        let hadGameFlag = defaults.object(forKey: Constants.Keys.gamePauseEnabled) != nil
        guard hadGameIDs || hadGameFlag else { return }

        if let data = defaults.data(forKey: Constants.Keys.watchedGameBundleIDs),
           let gameIDs = try? JSONDecoder().decode(Set<String>.self, from: data),
           !gameIDs.isEmpty {
            saveWatchedBundleIDs(loadWatchedBundleIDs().union(gameIDs))
        }
        if defaults.bool(forKey: Constants.Keys.gamePauseEnabled) {
            defaults.set(true, forKey: Constants.Keys.appAwarePauseEnabled)
        }
        defaults.removeObject(forKey: Constants.Keys.watchedGameBundleIDs)
        defaults.removeObject(forKey: Constants.Keys.gamePauseEnabled)
        DebugLog.log("AppWatcher: migrated legacy game pause settings into unified list")
    }

    // MARK: - Observers

    private func setupObservers() {
        let wsCenter = NSWorkspace.shared.notificationCenter

        launchObserver = wsCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluate()
        }

        terminateObserver = wsCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluate()
        }

        // Deferred to next run loop iteration to avoid reentrancy during startup
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.evaluate()
            }
        }
    }

    deinit {
        if let obs = launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        if let obs = terminateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        if let obs = defaultsObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

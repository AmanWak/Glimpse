//
//  GameModeMonitor.swift
//  Glimpse
//
//  Pauses Glimpse while a game is in the foreground. macOS exposes no API to read
//  Game Mode directly, so we mirror the same signal Game Mode itself uses: a
//  game-category app (LSApplicationCategoryType) that is the frontmost application.
//

import AppKit

final class GameModeMonitor {
    /// Called when a game becomes frontmost (and the feature is enabled). Passes the
    /// game's display name for the "Paused — X detected" status.
    var onShouldPause: ((String) -> Void)?

    /// Called when the frontmost app is no longer a game (and the feature is enabled).
    var onShouldResume: (() -> Void)?

    /// Whether this monitor triggered the current pause
    private(set) var isPausing = false

    /// When true, ignore game activations until a non-game is frontmost once
    private(set) var suppressedUntilClear = false

    private var activateObserver: NSObjectProtocol?
    private var deactivateObserver: NSObjectProtocol?
    private var defaultsObserver: NSObjectProtocol?

    // MARK: - Injectable config (defaults read from UserDefaults / NSWorkspace)

    /// Enabled with default ON — the user wants breaks off during games out of the box.
    /// Mirrors the codebase pattern of treating an unset key as its default value.
    var configEnabled: () -> Bool = {
        let key = Constants.Keys.gameModePauseEnabled
        if UserDefaults.standard.object(forKey: key) == nil { return true }
        return UserDefaults.standard.bool(forKey: key)
    }

    /// The frontmost app's display name if it is a game, otherwise nil.
    var frontmostGameName: () -> String? = {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let url = app.bundleURL,
              let bundle = Bundle(url: url),
              let category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String,
              GameModeMonitor.isGameCategory(category) else { return nil }
        return app.localizedName ?? "Game"
    }

    init() {
        setupObservers()
    }

    /// Convenience init that skips observers (for testing)
    init(skipObservers: Bool) {
        if !skipObservers { setupObservers() }
    }

    private func setupObservers() {
        let wsCenter = NSWorkspace.shared.notificationCenter
        activateObserver = wsCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.evaluate() }

        deactivateObserver = wsCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.evaluate() }

        // Re-evaluate immediately when the setting is toggled in Settings
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.evaluate() }
        }
    }

    func evaluate() {
        guard configEnabled() else {
            if isPausing { isPausing = false; onShouldResume?() }
            return
        }
        let game = frontmostGameName()
        let inGame = game != nil
        if suppressedUntilClear {
            if !inGame { suppressedUntilClear = false }
            return
        }
        if inGame && !isPausing {
            isPausing = true
            onShouldPause?(game ?? "Game")
        } else if !inGame && isPausing {
            isPausing = false
            onShouldResume?()
        }
    }

    /// Suppress pausing until a non-game is frontmost once (used on manual resume)
    func suppressUntilClear() {
        suppressedUntilClear = true
        isPausing = false
    }

    // MARK: - Detection

    /// True for `public.app-category.games` and every `*-games` subcategory
    /// (action-games, arcade-games, role-playing-games, …).
    static func isGameCategory(_ category: String) -> Bool {
        category == "public.app-category.games" || category.hasSuffix("-games")
    }

    deinit {
        let wsCenter = NSWorkspace.shared.notificationCenter
        if let obs = activateObserver { wsCenter.removeObserver(obs) }
        if let obs = deactivateObserver { wsCenter.removeObserver(obs) }
        if let obs = defaultsObserver { NotificationCenter.default.removeObserver(obs) }
    }
}

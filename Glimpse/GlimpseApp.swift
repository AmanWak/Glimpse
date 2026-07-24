//
//  GlimpseApp.swift
//  Glimpse
//
//  A macOS menu bar app implementing the 20-20-20 rule for eye health.
//

import SwiftUI

/// Menu bar label that shows icon + optional countdown text.
/// Uses HStack instead of Label because MenuBarExtra applies icon-only
/// label style. Observes AppState directly so updates are reactive.
private struct MenuBarLabel: View {
    let appState: AppState

    var body: some View {
        HStack(spacing: 3) {
            Image("MenuBarIcon")
            // Only render the countdown when there is one — keeps the item compact and
            // perfectly centered on the icon when paused/idle (label is "" then).
            if !appState.menuBarLabel.isEmpty {
                Text(appState.menuBarLabel)
                    .monospacedDigit()
            }
        }
    }
}

@main
struct GlimpseApp: App {
    @State private var appState = AppState()
    @State private var timerManager = TimerManager()
    @State private var overlayManager = OverlayManager()
    @State private var bannerManager = BannerManager()
    @State private var notchManager = NotchManager()
    @State private var appWatcher: AppWatcher?
    @State private var sleepWakeHandler: SleepWakeHandler?
    @State private var isInitialized = false

    /// Track if timer was running before sleep/pause
    @State private var wasRunningBeforeSleep = false

    /// Timestamp when system entered sleep
    @State private var sleepTimestamp: Date?

    /// Track if heads-up notification was sent this work cycle
    @State private var headsUpSent = false

    /// Pending snooze wake-up
    @State private var snoozeWorkItem: DispatchWorkItem?

    /// Sources that have auto-triggered a pause ("apps" and/or "controller")
    @State private var activePauseSources: Set<String> = []

    /// Monitors game controller connect/disconnect events
    @State private var gameControllerMonitor: GameControllerMonitor?

    /// Pauses while a game is frontmost (mirrors macOS Game Mode's own trigger)
    @State private var gameModeMonitor: GameModeMonitor?

    var body: some Scene {
        // Menu bar
        MenuBarExtra {
            MenuBarView(
                appState: appState,
                onPauseResume: handlePauseResume,
                onSnooze: handleSnooze,
                onSkipToBreak: startBreak,
                onSkipBreak: { skipBreak() },
                onQuit: handleQuit
            )
        } label: {
            MenuBarLabel(appState: appState)
                .onAppear {
                    initializeIfNeeded()
                }
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView(appState: appState)
        }
    }

    init() {
        // Set up notification delegate so notifications show while app is active
        NotificationManager.shared.setupDelegate()
    }

    private func initializeIfNeeded() {
        guard !isInitialized else { return }
        isInitialized = true

        // When the app is hosting unit tests, stay inert — timers, watchers, and
        // the settings migration would otherwise race the tests on UserDefaults.
        if NSClassFromString("XCTestCase") != nil {
            DebugLog.log("GlimpseApp: test host detected — skipping startup")
            return
        }
        DebugLog.log("GlimpseApp: first-time setup")

        // Request notification permission (must happen after app is running)
        NotificationManager.shared.requestPermission()

        // One-time setup
        AppWatcher.migrateLegacyGameSettings()
        setupTimerCallbacks()
        setupSleepWakeHandler()

        // Start the first work cycle
        appState.startWorkPeriod()
        timerManager.startWorkTimer(duration: appState.workDuration)

        // App watcher must start AFTER work timer so it can pause a running timer
        setupAppWatcher()
        setupGameControllerMonitor()
        setupGameModeMonitor()
    }

    // MARK: - Lifecycle

    private func setupTimerCallbacks() {
        timerManager.onTick = { [self] remaining in
            appState.secondsRemaining = remaining

            // Send heads-up notification 30s before break
            if appState.mode == .working
                && appState.headsUpNotification
                && !headsUpSent
                && remaining <= Constants.headsUpLeadTime {
                headsUpSent = true
                NotificationManager.shared.showHeadsUpNotification()
            }
        }

        timerManager.onWorkComplete = { [self] in
            DebugLog.log("GlimpseApp: onWorkComplete — deferring startBreak()")
            DispatchQueue.main.async {
                startBreakWhenTypingPauses()
            }
        }

        timerManager.onBreakComplete = { [self] in
            DebugLog.log("GlimpseApp: onBreakComplete — deferring completeBreak()")
            DispatchQueue.main.async {
                completeBreak()
            }
        }
    }

    private func setupSleepWakeHandler() {
        sleepWakeHandler = SleepWakeHandler()

        sleepWakeHandler?.onSleep = { [self] in
            DebugLog.log("GlimpseApp: onSleep — mode=\(appState.mode)")
            sleepTimestamp = Date()
            if appState.mode != .paused {
                wasRunningBeforeSleep = true
                timerManager.pause()
                appState.pause()
            } else {
                wasRunningBeforeSleep = false
            }
        }

        sleepWakeHandler?.onWake = { [self] in
            let sleepDuration = sleepTimestamp.map { Date().timeIntervalSince($0) } ?? 0
            sleepTimestamp = nil
            DebugLog.log("GlimpseApp: onWake — wasRunning=\(wasRunningBeforeSleep), sleepDuration=\(Int(sleepDuration))s")

            if wasRunningBeforeSleep {
                wasRunningBeforeSleep = false

                if sleepDuration >= Constants.sleepResetThreshold {
                    // Long sleep — reset the work timer fresh
                    DebugLog.log("GlimpseApp: sleep exceeded threshold, resetting work timer")
                    hideAllVisuals()
                    headsUpSent = false
                    appState.startWorkPeriod()
                    timerManager.startWorkTimer(duration: appState.workDuration)
                } else {
                    resumeTimer()
                }
            }
        }
    }

    private func setupAppWatcher() {
        let watcher = AppWatcher()
        watcher.onShouldPause = { [self] appNames in
            autoPause(source: "apps", triggeredBy: appNames)
        }
        watcher.onShouldResume = { [self] in
            autoResume(source: "apps")
        }
        appWatcher = watcher
        watcher.evaluate()
    }

    private func setupGameControllerMonitor() {
        let monitor = GameControllerMonitor()
        monitor.onShouldPause = { [self] in
            autoPause(source: "controller", triggeredBy: ["Game Controller"])
        }
        monitor.onShouldResume = { [self] in
            autoResume(source: "controller")
        }
        gameControllerMonitor = monitor
        monitor.evaluate()
    }

    private func setupGameModeMonitor() {
        let monitor = GameModeMonitor()
        monitor.onShouldPause = { [self] name in
            autoPause(source: "gameMode", triggeredBy: [name])
        }
        monitor.onShouldResume = { [self] in
            autoResume(source: "gameMode")
        }
        gameModeMonitor = monitor
        monitor.evaluate()
    }

    // MARK: - Auto-Pause

    /// Pause triggered by an auto-pause source (watched app or controller).
    private func autoPause(source: String, triggeredBy names: [String]) {
        activePauseSources.insert(source)
        guard appState.mode != .paused else { return }
        DebugLog.log("GlimpseApp: \(source) triggered pause — \(names)")
        timerManager.pause()
        appState.pause()
        appState.pausedByAppNames = names
        hideAllVisuals()
    }

    /// Resume when an auto-pause source clears — but only once all sources have.
    private func autoResume(source: String) {
        activePauseSources.remove(source)
        guard activePauseSources.isEmpty, appState.pausedByAppNames != nil else { return }
        DebugLog.log("GlimpseApp: \(source) triggered resume")
        appState.pausedByAppNames = nil
        resumeTimer()
    }

    // MARK: - Timer Control

    /// Start the break now, or — if the user is mid-keystroke and the setting
    /// is on — hold it until a short pause in typing (capped at maxBreakHold).
    private func startBreakWhenTypingPauses() {
        guard appState.mode == .working else { return }
        guard appState.holdBreakWhileTyping,
              InputActivity.secondsSinceLastKeyPress() < Constants.typingPauseThreshold else {
            startBreak()
            return
        }
        DebugLog.log("GlimpseApp: holding break — user is typing")
        appState.isAwaitingBreak = true
        pollForTypingPause(deadline: Date().addingTimeInterval(Constants.maxBreakHold))
    }

    /// Re-check every half second until typing pauses or the hold cap is hit.
    /// Exits silently if the user pauses/snoozes meanwhile (pause() clears
    /// isAwaitingBreak; the resumed 0s work timer re-fires onWorkComplete).
    private func pollForTypingPause(deadline: Date) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            guard appState.mode == .working, appState.isAwaitingBreak else { return }
            if Date() >= deadline
                || InputActivity.secondsSinceLastKeyPress() >= Constants.typingPauseThreshold {
                startBreak()
            } else {
                pollForTypingPause(deadline: deadline)
            }
        }
    }

    private func startBreak() {
        guard appState.mode == .working else { return }
        DebugLog.log("GlimpseApp.startBreak() — breakStyle=\(appState.breakStyle)")

        headsUpSent = false
        appState.startBreak()

        let breakDur = appState.breakDuration
        switch appState.breakStyle {
        case .notification:
            NotificationManager.shared.showBreakNotification(message: appState.currentMessage)
            timerManager.startBreakTimer(duration: breakDur)
        case .banner:
            showBanner()
            timerManager.startBreakTimer(duration: breakDur)
        case .notch:
            showNotch()
            timerManager.startBreakTimer(duration: breakDur)
        case .overlay:
            showOverlay()
            timerManager.startBreakTimer(duration: breakDur)
        }

        appState.isOverlayShowing = overlayManager.isShowing
    }

    private func completeBreak() {
        guard appState.mode == .onBreak else { return }
        DebugLog.log("GlimpseApp.completeBreak()")

        if appState.playSoundOnBreakEnd {
            NSSound(named: "Glass")?.play()
        }

        hideAllVisuals()
        appState.completeBreak()
        timerManager.startWorkTimer(duration: appState.workDuration)

        if appState.breakStyle == .notification {
            NotificationManager.shared.showBreakCompleteNotification()
        }
    }

    private func skipBreak() {
        guard appState.mode == .onBreak else { return }
        DebugLog.log("GlimpseApp.skipBreak()")

        hideAllVisuals()
        appState.skipBreak()
        timerManager.startWorkTimer(duration: appState.workDuration)
    }

    private func resumeTimer() {
        appState.resume()
        timerManager.resume(
            remainingTime: appState.secondsRemaining,
            isBreak: appState.mode == .onBreak
        )
        // Re-show visual break if resuming into a break
        if appState.mode == .onBreak {
            switch appState.breakStyle {
            case .overlay:
                showOverlay()
            case .banner:
                showBanner()
            case .notch:
                showNotch()
            case .notification:
                break
            }
        }
    }

    // MARK: - Overlay

    private func showOverlay() {
        overlayManager.onDismiss = { [self] in
            skipBreak()
        }

        // Pass snapshot values to OverlayManager
        overlayManager.showOverlay(
            initialSeconds: Int(appState.secondsRemaining),
            overlayColor: Color(hex: appState.overlayColorHex),
            overlayOpacity: appState.overlayOpacity,
            message: appState.currentMessage,
            requireSkipConfirmation: appState.skipConfirmation && appState.streak.consecutiveSkips >= 2,
            notes: appState.breakNotesEnabled ? appState.breakNotes : [],
            onSkip: { [self] in
                skipBreak()
            }
        )
        appState.isOverlayShowing = true
    }

    private func hideOverlay() {
        overlayManager.onDismiss = nil
        overlayManager.hideOverlay()
        appState.isOverlayShowing = false
    }

    // MARK: - Banner

    private func showBanner() {
        bannerManager.onDismiss = { [self] in
            skipBreak()
        }

        bannerManager.showBanner(
            initialSeconds: Int(appState.secondsRemaining),
            overlayColor: Color(hex: appState.overlayColorHex)
        )
    }

    private func hideBanner() {
        bannerManager.onDismiss = nil
        bannerManager.hideBanner()
    }

    // MARK: - Notch

    private func showNotch() {
        notchManager.onDismiss = { [self] in
            skipBreak()
        }

        notchManager.showNotch(
            initialSeconds: Int(appState.secondsRemaining),
            overlayColor: Color(hex: appState.overlayColorHex)
        )
    }

    private func hideNotch() {
        notchManager.onDismiss = nil
        notchManager.hideNotch()
    }

    /// Hide whatever break visual is currently showing (overlay, banner, and/or notch).
    private func hideAllVisuals() {
        hideOverlay()
        hideBanner()
        hideNotch()
    }

    // MARK: - Menu Bar Actions

    private func handlePauseResume() {
        if appState.mode == .paused {
            cancelSnooze()
            activePauseSources.removeAll()
            appState.pausedByAppNames = nil
            appWatcher?.suppressUntilClear()
            gameControllerMonitor?.suppressUntilClear()
            gameModeMonitor?.suppressUntilClear()
            resumeTimer()
        } else {
            activePauseSources.removeAll()
            timerManager.pause()
            appState.pause()
            hideAllVisuals()
        }
    }

    private func handleSnooze(hours: Int) {
        cancelSnooze()
        activePauseSources.removeAll()
        appState.pausedByAppNames = nil
        appWatcher?.suppressUntilClear()
        gameControllerMonitor?.suppressUntilClear()
        gameModeMonitor?.suppressUntilClear()

        timerManager.pause()
        appState.pause()
        hideAllVisuals()

        appState.snoozeUntil = Date().addingTimeInterval(TimeInterval(hours * 3600))

        let item = DispatchWorkItem { [self] in
            guard appState.isSnoozed else { return }
            appState.snoozeUntil = nil
            resumeTimer()
        }
        snoozeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(hours * 3600), execute: item)
    }

    private func cancelSnooze() {
        snoozeWorkItem?.cancel()
        snoozeWorkItem = nil
        appState.snoozeUntil = nil
    }

    private func handleQuit() {
        appState.saveState()
        NotificationManager.shared.clearNotifications()
        NSApplication.shared.terminate(nil)
    }
}

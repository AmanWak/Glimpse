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
        HStack(spacing: 0) {
            Text(" " + appState.menuBarLabel)
                .monospacedDigit()
                .padding(.trailing, 8)
            Image("MenuBarIcon")
        }
    }
}

@main
struct GlimpseApp: App {
    @State private var appState = AppState()
    @State private var timerManager = TimerManager()
    @State private var overlayManager = OverlayManager()
    @State private var bannerManager = BannerManager()
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

    var body: some Scene {
        // Menu bar
        MenuBarExtra {
            MenuBarView(
                appState: appState,
                onPauseResume: handlePauseResume,
                onSnooze: handleSnooze,
                onSkipToBreak: handleSkipToBreak,
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
        DebugLog.log("GlimpseApp: first-time setup")

        // Request notification permission (must happen after app is running)
        NotificationManager.shared.requestPermission()

        // One-time setup
        setupTimerCallbacks()
        setupSleepWakeHandler()

        // Start the first work cycle
        appState.startWorkPeriod()
        timerManager.startWorkTimer(duration: appState.workDuration)

        // App watcher must start AFTER work timer so it can pause a running timer
        setupAppWatcher()
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
                startBreak()
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
                    hideOverlay()
                    hideBanner()
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
            guard appState.mode != .paused else { return }
            DebugLog.log("GlimpseApp: AppWatcher triggered pause — \(appNames)")
            timerManager.pause()
            appState.pause()
            appState.pausedByAppNames = appNames
            hideOverlay()
            hideBanner()
        }

        watcher.onShouldResume = { [self] in
            guard appState.pausedByAppNames != nil else { return }
            DebugLog.log("GlimpseApp: AppWatcher triggered resume")
            appState.pausedByAppNames = nil
            resumeTimer()
        }

        appWatcher = watcher
        watcher.evaluate()
    }

    // MARK: - Timer Control

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

        hideOverlay()
        hideBanner()
        appState.completeBreak()
        timerManager.startWorkTimer(duration: appState.workDuration)

        if appState.breakStyle == .notification {
            NotificationManager.shared.showBreakCompleteNotification()
        }
    }

    private func skipBreak() {
        guard appState.mode == .onBreak else { return }
        DebugLog.log("GlimpseApp.skipBreak()")

        hideOverlay()
        hideBanner()
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

    // MARK: - Menu Bar Actions

    private func handlePauseResume() {
        if appState.mode == .paused {
            cancelSnooze()
            appState.pausedByAppNames = nil
            appWatcher?.suppressUntilClear()
            resumeTimer()
        } else {
            timerManager.pause()
            appState.pause()
            hideOverlay()
            hideBanner()
        }
    }

    private func handleSnooze(hours: Int) {
        cancelSnooze()
        appState.pausedByAppNames = nil
        appWatcher?.suppressUntilClear()

        timerManager.pause()
        appState.pause()
        hideOverlay()
        hideBanner()

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

    private func handleSkipToBreak() {
        startBreak()
    }

    private func handleQuit() {
        appState.saveState()
        NotificationManager.shared.clearNotifications()
        NSApplication.shared.terminate(nil)
    }
}

//
//  GlimpseApp.swift
//  Glimpse
//
//  A macOS menu bar app implementing the 20-20-20 rule for eye health.
//

import SwiftUI

@main
struct GlimpseApp: App {
    @State private var appState = AppState()
    @State private var timerManager = TimerManager()
    @State private var overlayManager = OverlayManager()
    @State private var sleepWakeHandler: SleepWakeHandler?
    @State private var isInitialized = false

    /// Track if timer was running before sleep/pause
    @State private var wasRunningBeforeSleep = false

    var body: some Scene {
        // Menu bar
        MenuBarExtra {
            MenuBarView(
                appState: appState,
                onPauseResume: handlePauseResume,
                onSkipToBreak: handleSkipToBreak,
                onQuit: handleQuit
            )
        } label: {
            Image(systemName: appState.menuBarIcon)
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
        // Request notification permission
        NotificationManager.shared.requestPermission()
    }

    private func initializeIfNeeded() {
        guard !isInitialized else { return }
        isInitialized = true

        // One-time setup
        setupTimerCallbacks()
        setupSleepWakeHandler()

        // Start the first work cycle
        appState.startWorkPeriod()
        timerManager.startWorkTimer()
    }

    // MARK: - Lifecycle

    private func setupTimerCallbacks() {
        timerManager.onTick = { [self] remaining in
            appState.secondsRemaining = remaining
        }

        timerManager.onWorkComplete = { [self] in
            startBreak()
        }

        timerManager.onBreakComplete = { [self] in
            completeBreak()
        }
    }

    private func setupSleepWakeHandler() {
        sleepWakeHandler = SleepWakeHandler()

        sleepWakeHandler?.onSleep = { [self] in
            if appState.mode != .paused {
                wasRunningBeforeSleep = true
                timerManager.pause()
                appState.pause()
            } else {
                wasRunningBeforeSleep = false
            }
        }

        sleepWakeHandler?.onWake = { [self] in
            if wasRunningBeforeSleep {
                wasRunningBeforeSleep = false
                resumeTimer()
            }
        }
    }

    // MARK: - Timer Control

    private func startBreak() {
        guard appState.mode == .working else { return }

        appState.startBreak()

        // Check if fullscreen app is active or user prefers notifications
        if overlayManager.isFullscreenAppActive || appState.breakStyle == .notification {
            NotificationManager.shared.showBreakNotification()
            timerManager.startBreakTimer()
        } else {
            showOverlay()
            timerManager.startBreakTimer()
        }

        appState.isOverlayShowing = overlayManager.isShowing
    }

    private func completeBreak() {
        guard appState.mode == .onBreak else { return }

        // Disconnect overlay FIRST — replaces the SwiftUI view tree with EmptyView,
        // which cancels all @Observable observations and in-flight animations.
        // This makes it safe to change state without triggering re-renders on a
        // view tree that's about to be freed (which causes EXC_BAD_ACCESS).
        hideOverlay()

        appState.completeBreak()
        timerManager.startWorkTimer()

        if appState.breakStyle == .notification {
            NotificationManager.shared.showBreakCompleteNotification()
        }
    }

    private func skipBreak() {
        guard appState.mode == .onBreak else { return }

        // Disconnect overlay first, then change state (same pattern).
        hideOverlay()

        appState.skipBreak()
        timerManager.startWorkTimer()
    }

    private func resumeTimer() {
        appState.resume()
        timerManager.resume(
            remainingTime: appState.secondsRemaining,
            isBreak: appState.mode == .onBreak
        )
        // Re-show overlay if resuming into a break
        if appState.mode == .onBreak
            && appState.breakStyle == .overlay
            && !overlayManager.isFullscreenAppActive {
            showOverlay()
        }
    }

    // MARK: - Overlay

    private func showOverlay() {
        overlayManager.onDismiss = { [self] in
            skipBreak()
        }

        // Pass snapshot values to OverlayManager — it owns the countdown timer
        // and updates the view each tick. No Combine timers or @State inside the
        // overlay view, so nothing can fire into freed memory after teardown.
        overlayManager.showOverlay(
            initialSeconds: Int(appState.secondsRemaining),
            overlayColor: Color(hex: appState.overlayColorHex),
            overlayOpacity: appState.overlayOpacity,
            message: appState.currentMessage,
            requireSkipConfirmation: appState.skipConfirmation && appState.streak.consecutiveSkips >= 2,
            onSkip: { [self] in
                // Defer to next run loop cycle so the SwiftUI button event finishes
                // before we tear down the NSWindow that hosts it (prevents EXC_BAD_ACCESS)
                DispatchQueue.main.async {
                    skipBreak()
                }
            }
        )
        appState.isOverlayShowing = true
    }

    private func hideOverlay() {
        overlayManager.onDismiss = nil
        appState.isOverlayShowing = false   // state change FIRST
        overlayManager.hideOverlay()        // teardown LAST
    }

    // MARK: - Menu Bar Actions

    private func handlePauseResume() {
        if appState.mode == .paused {
            resumeTimer()
        } else {
            timerManager.pause()
            appState.pause()
            hideOverlay()
        }
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

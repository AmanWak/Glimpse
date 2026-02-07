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
            .onAppear {
                initializeIfNeeded()
            }
        } label: {
            Image(systemName: appState.menuBarIcon)
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
        startWorkTimer()
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

    private func startWorkTimer() {
        setupTimerCallbacks()
        setupSleepWakeHandler()
        appState.startWorkPeriod()
        timerManager.startWorkTimer()
    }

    private func startBreak() {
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
        hideOverlay()
        appState.completeBreak()
        timerManager.startWorkTimer()

        if appState.breakStyle == .notification {
            NotificationManager.shared.showBreakCompleteNotification()
        }
    }

    private func skipBreak() {
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
    }

    // MARK: - Overlay

    private func showOverlay() {
        let overlayView = OverlayView(
            appState: appState,
            onSkip: { [self] in
                skipBreak()
            }
        )
        overlayManager.showOverlay(content: overlayView)
        appState.isOverlayShowing = true
    }

    private func hideOverlay() {
        overlayManager.hideOverlay()
        appState.isOverlayShowing = false
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
        NSApplication.shared.terminate(nil)
    }
}

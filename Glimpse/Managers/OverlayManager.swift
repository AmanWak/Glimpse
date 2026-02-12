//
//  OverlayManager.swift
//  Glimpse
//
//  Creates and manages full-screen overlay windows on all displays.
//  Owns the countdown timer and updates the overlay view each tick.
//  The timer is invalidated BEFORE window teardown, ensuring no
//  callbacks can fire into freed SwiftUI state.
//

import AppKit
import SwiftUI

final class OverlayManager {
    private var overlayWindows: [NSWindow] = []
    private var safetyTimer: Timer?
    private var escapeMonitor: Any?
    private var countdownTimer: Timer?

    /// Snapshot values for rebuilding the overlay view each tick
    private var currentSeconds: Int = 0
    private var overlayColor: Color = .black
    private var overlayOpacity: Double = 0.85
    private var message: String = ""
    private var requireSkipConfirmation: Bool = false
    private var skipAction: (() -> Void)?

    /// Called when overlay is dismissed via safety timeout or Escape key
    var onDismiss: (() -> Void)?

    /// Check if any app is in fullscreen mode
    var isFullscreenAppActive: Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        // Check if the frontmost app has any fullscreen windows
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        for windowInfo in windowList {
            guard let windowPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  windowPID == frontApp.processIdentifier,
                  let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }

            // Check if window covers the entire screen
            for screen in NSScreen.screens {
                let screenFrame = screen.frame
                if let width = bounds["Width"], let height = bounds["Height"],
                   width >= screenFrame.width && height >= screenFrame.height {
                    return true
                }
            }
        }

        return false
    }

    /// Show overlay on all screens with the given snapshot values
    func showOverlay(initialSeconds: Int, overlayColor: Color, overlayOpacity: Double,
                     message: String, requireSkipConfirmation: Bool, onSkip: @escaping () -> Void) {
        hideOverlay()

        // Store snapshot values
        self.currentSeconds = initialSeconds
        self.overlayColor = overlayColor
        self.overlayOpacity = overlayOpacity
        self.message = message
        self.requireSkipConfirmation = requireSkipConfirmation
        self.skipAction = onSkip

        // Create windows with initial view
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            overlayWindows.append(window)
            window.orderFront(nil)
        }

        startCountdownTimer()
        startSafetyTimer()
        startEscapeMonitor()
    }

    /// Hide all overlay windows — fully synchronous to prevent zombie window period.
    /// Countdown timer is invalidated FIRST so no tick callbacks can fire during
    /// or after teardown. Any @Observable state mutations after this returns are
    /// safe because both the timer and NSHostingViews are already destroyed.
    func hideOverlay() {
        // 1. Stop ALL timers FIRST — no more callbacks can fire
        countdownTimer?.invalidate()
        countdownTimer = nil
        stopSafetyTimer()
        stopEscapeMonitor()

        // 2. Clear closure references to break retain cycles
        skipAction = nil

        guard !overlayWindows.isEmpty else { return }

        // 3. Tear down windows
        let windows = overlayWindows
        overlayWindows.removeAll()

        for window in windows {
            // Replace SwiftUI tree to cancel any internal subscriptions
            if let hostingView = window.contentView as? NSHostingView<AnyView> {
                hostingView.rootView = AnyView(EmptyView())
            }
            // Destroy hosting view immediately
            window.contentView = nil
            // Remove from screen and close
            window.orderOut(nil)
            window.close()
        }
    }

    /// Check if overlay is currently showing
    var isShowing: Bool {
        return !overlayWindows.isEmpty
    }

    // MARK: - Private

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = makeOverlayView()
        let hostingView = NSHostingView(rootView: AnyView(view))
        hostingView.frame = screen.frame
        window.contentView = hostingView

        return window
    }

    private func makeOverlayView() -> OverlayView {
        OverlayView(
            seconds: currentSeconds,
            overlayColor: overlayColor,
            overlayOpacity: overlayOpacity,
            message: message,
            requireSkipConfirmation: requireSkipConfirmation,
            onSkip: skipAction ?? {}
        )
    }

    // MARK: - Countdown Timer

    /// Ticks every second, decrements the counter, and pushes a new snapshot
    /// into each overlay window's NSHostingView. Because this is a plain
    /// Foundation Timer (not Combine Timer.publish), it is invalidated
    /// deterministically in hideOverlay() before any view teardown.
    private func startCountdownTimer() {
        let timer = Timer(timeInterval: Constants.timerTickInterval, repeats: true) { [weak self] _ in
            guard let self, !self.overlayWindows.isEmpty else { return }
            self.currentSeconds = max(0, self.currentSeconds - 1)
            self.updateOverlayViews()
        }
        countdownTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func updateOverlayViews() {
        let view = makeOverlayView()
        for window in overlayWindows {
            if let hostingView = window.contentView as? NSHostingView<AnyView> {
                hostingView.rootView = AnyView(view)
            }
        }
    }

    // MARK: - Safety Timer

    /// Auto-dismiss overlay after break duration + 5s buffer as a failsafe
    private func startSafetyTimer() {
        let timer = Timer(timeInterval: Constants.breakDuration + 5, repeats: false) { [weak self] _ in
            guard let self, self.isShowing else { return }
            self.onDismiss?()
        }
        safetyTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func stopSafetyTimer() {
        safetyTimer?.invalidate()
        safetyTimer = nil
    }

    // MARK: - Escape Key Monitor

    private func startEscapeMonitor() {
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                guard let self, self.isShowing else { return event }
                self.onDismiss?()
                return nil // consume the event
            }
            return event
        }
    }

    private func stopEscapeMonitor() {
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }
}

//
//  OverlayManager.swift
//  Glimpse
//
//  Creates and manages full-screen overlay windows on all displays.
//  Owns the countdown timer AND skip-confirmation state. Updates the
//  overlay view each tick with a fresh snapshot.
//
//  IMPORTANT: Window teardown must NOT call contentView=nil or close().
//  These trigger a deferred AppKit/SwiftUI rendering pass that deadlocks
//  the main thread when NSVisualEffectView is in the view hierarchy.
//  Instead, replace rootView with EmptyView (to break closure retain
//  paths), orderOut the window, and drop all references so ARC handles
//  deallocation naturally.
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
    private var showingSkipConfirmation: Bool = false
    private var skipAction: (() -> Void)?

    /// Called when overlay is dismissed via safety timeout or Escape key
    var onDismiss: (() -> Void)?

    /// Show overlay on all screens with the given snapshot values.
    func showOverlay(initialSeconds: Int, overlayColor: Color, overlayOpacity: Double,
                     message: String, requireSkipConfirmation: Bool, onSkip: @escaping () -> Void) {
        DebugLog.log("OverlayManager.showOverlay() — initialSeconds=\(initialSeconds), screens=\(NSScreen.screens.count)")
        hideOverlay()

        // Store snapshot values
        self.currentSeconds = initialSeconds
        self.overlayColor = overlayColor
        self.overlayOpacity = overlayOpacity
        self.message = message
        self.requireSkipConfirmation = requireSkipConfirmation
        self.showingSkipConfirmation = false
        self.skipAction = onSkip

        // Dismiss any open menu bar popover before showing overlay
        for window in NSApp.windows where window is NSPanel {
            window.orderOut(nil)
        }

        // Create windows with initial view
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            overlayWindows.append(window)
            window.orderFront(nil)
        }

        startCountdownTimer()
        startSafetyTimer()
        startEscapeMonitor()
        DebugLog.log("OverlayManager.showOverlay() — \(overlayWindows.count) windows showing")
    }

    /// Hide all overlay windows.
    func hideOverlay() {
        guard !overlayWindows.isEmpty || countdownTimer != nil || safetyTimer != nil else { return }
        DebugLog.log("OverlayManager.hideOverlay() — windowCount=\(overlayWindows.count)")

        // 1. Stop ALL timers and monitors — no more callbacks can fire
        countdownTimer?.invalidate()
        countdownTimer = nil
        stopSafetyTimer()
        stopEscapeMonitor()

        // 2. Clear closure references
        skipAction = nil
        showingSkipConfirmation = false

        // 3. Disconnect SwiftUI views, hide windows, and release references.
        //    Do NOT call contentView=nil or close() — these trigger a deferred
        //    AppKit/SwiftUI teardown that deadlocks the main thread.
        for window in overlayWindows {
            if let hostingView = window.contentView as? NSHostingView<AnyView> {
                hostingView.rootView = AnyView(EmptyView())
            }
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }

    /// Check if overlay is currently showing
    var isShowing: Bool {
        return !overlayWindows.isEmpty
    }

    /// Check if any full-screen app is active (to decide if we should fallback to notifications)
    func canShowOverlay() -> Bool {
        // Check if any full-screen app is active
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return true
        }

        // Check active window for full-screen mode
        // We use CGWindowListCopyWindowInfo to get info about all on-screen windows
        if let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] {
            for windowInfo in windows {
                if let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                   ownerPID == frontmostApp.processIdentifier,
                   let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                   let screen = NSScreen.main {
                    // Compare window bounds to screen bounds
                    // If height is >= screen height, it's likely a full-screen app
                    let windowHeight = bounds["Height"] as? CGFloat ?? 0
                    let screenHeight = screen.frame.height
                    if windowHeight >= screenHeight {
                        DebugLog.log("OverlayManager.canShowOverlay() — detected full-screen app: \(frontmostApp.localizedName ?? "unknown")")
                        return false
                    }
                }
            }
        }
        return true
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
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

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
            showingSkipConfirmation: showingSkipConfirmation,
            onSkip: { [weak self] in self?.handleSkipTapped() },
            onCancelSkip: { [weak self] in self?.handleCancelSkip() }
        )
    }

    // MARK: - Skip Confirmation

    private func handleSkipTapped() {
        if requireSkipConfirmation && !showingSkipConfirmation {
            showingSkipConfirmation = true
            updateOverlayViews()
        } else {
            let action = skipAction
            DispatchQueue.main.async {
                action?()
            }
        }
    }

    private func handleCancelSkip() {
        showingSkipConfirmation = false
        updateOverlayViews()
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        let timer = Timer(timeInterval: Constants.timerTickInterval, repeats: true) { [weak self] timer in
            guard let self, !self.overlayWindows.isEmpty else {
                timer.invalidate()
                return
            }
            self.currentSeconds = max(0, self.currentSeconds - 1)
            if self.currentSeconds <= 0 {
                // Stop ticking — don't update views when teardown is imminent
                timer.invalidate()
                self.countdownTimer = nil
                return
            }
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

    private func startSafetyTimer() {
        let duration = Constants.breakDuration + 5
        let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
            guard let self, self.isShowing else { return }
            DebugLog.log("OverlayManager: safetyTimer FIRED — calling onDismiss")
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

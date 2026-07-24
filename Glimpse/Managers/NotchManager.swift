//
//  NotchManager.swift
//  Glimpse
//
//  Creates and manages a Live-Activity-style pill pinned to the notch (or top-center of
//  any screen) during breaks. Uses the same snapshot/callback pattern as BannerManager.
//
//  IMPORTANT: Window teardown must NOT call contentView=nil or close().
//  Instead, replace rootView with EmptyView, orderOut, and drop references.
//

import AppKit
import SwiftUI

/// NSWindow subclass that disables AppKit's automatic frame constraining so the pill can
/// sit flush against the top of the screen, in the notch / menu-bar region.
private final class UnconstrainedWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

final class NotchManager {
    private var notchWindow: NSWindow?
    private var countdownTimer: Timer?
    private var safetyTimer: Timer?

    /// Snapshot values for rebuilding the view each tick
    private var currentSeconds: Int = 0
    private var overlayColor: Color = .clear
    private var topInset: CGFloat = 0

    /// Called when the pill dismisses itself via safety timeout
    var onDismiss: (() -> Void)?

    // MARK: - Public

    /// Show the notch pill with the given snapshot values.
    func showNotch(initialSeconds: Int, overlayColor: Color) {
        DebugLog.log("NotchManager.showNotch() — initialSeconds=\(initialSeconds)")
        hideNotch()

        guard let metrics = notchMetrics() else {
            DebugLog.log("NotchManager.showNotch() — no screen available")
            return
        }

        self.currentSeconds = initialSeconds
        self.overlayColor = overlayColor
        self.topInset = metrics.topInset

        // Dismiss any open menu bar popover before showing the pill.
        for window in NSApp.windows where window is NSPanel {
            window.orderOut(nil)
        }

        let window = createNotchWindow(frame: metrics.frame)
        notchWindow = window
        window.alphaValue = 0
        window.orderFront(nil)

        // Gentle live-activity fade-in (AppKit-level only — safe with NSHostingView).
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            window.animator().alphaValue = 1
        }

        startCountdownTimer()
        startSafetyTimer()
        DebugLog.log("NotchManager.showNotch() — pill showing")
    }

    /// Hide the pill window and clean up all resources.
    func hideNotch() {
        guard notchWindow != nil || countdownTimer != nil || safetyTimer != nil else { return }
        DebugLog.log("NotchManager.hideNotch()")

        // 1. Clear closure references
        onDismiss = nil

        // 2. Stop all timers
        countdownTimer?.invalidate()
        countdownTimer = nil
        safetyTimer?.invalidate()
        safetyTimer = nil

        // 3. Disconnect SwiftUI view, hide window, drop reference
        if let window = notchWindow {
            if let hostingView = window.contentView as? NSHostingView<AnyView> {
                hostingView.rootView = AnyView(EmptyView())
            }
            window.orderOut(nil)
        }
        notchWindow = nil
    }

    /// Whether the pill is currently showing
    var isShowing: Bool {
        return notchWindow != nil
    }

    // MARK: - Geometry

    /// The pill frame flush to the top-center of the active screen, plus the notch height
    /// (0 when the screen has no notch). Returns nil only if there is no screen at all.
    private func notchMetrics() -> (frame: NSRect, topInset: CGFloat)? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return nil }
        let inset = screen.safeAreaInsets.top
        let width: CGFloat
        let height: CGFloat
        if inset > 0 {
            // Notched screen — size the pill to hug the notch and drop below it.
            let auxLeft = screen.auxiliaryTopLeftArea?.width ?? 0
            let auxRight = screen.auxiliaryTopRightArea?.width ?? 0
            let notchWidth = max(0, screen.frame.width - auxLeft - auxRight)
            width = max(240, notchWidth + 90)
            height = inset + 46
        } else {
            // No notch — a top-center floating pill.
            width = 260
            height = 64
        }
        let x = screen.frame.midX - width / 2
        let y = screen.frame.maxY - height
        return (NSRect(x: x, y: y, width: width, height: height), inset)
    }

    // MARK: - Window Creation

    private func createNotchWindow(frame: NSRect) -> NSWindow {
        let window = UnconstrainedWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .statusBar
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let hostingView = NSHostingView(rootView: AnyView(makeNotchView()))
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        window.contentView = hostingView

        return window
    }

    private func makeNotchView() -> AnyView {
        AnyView(
            NotchView(seconds: currentSeconds, overlayColor: overlayColor, topInset: topInset)
        )
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        let timer = Timer(timeInterval: Constants.timerTickInterval, repeats: true) { [weak self] timer in
            guard let self, self.notchWindow != nil else {
                timer.invalidate()
                return
            }
            self.currentSeconds = max(0, self.currentSeconds - 1)
            if self.currentSeconds <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                return
            }
            self.updateNotchView()
        }
        countdownTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func updateNotchView() {
        if let window = notchWindow,
           let hostingView = window.contentView as? NSHostingView<AnyView> {
            hostingView.rootView = makeNotchView()
        }
    }

    // MARK: - Safety Timer

    private func startSafetyTimer() {
        let duration = TimeInterval(currentSeconds) + 5
        let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
            guard let self, self.isShowing else { return }
            DebugLog.log("NotchManager: safetyTimer FIRED — calling onDismiss")
            self.onDismiss?()
        }
        safetyTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
}

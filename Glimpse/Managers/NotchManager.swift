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
import QuartzCore
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

    /// How far above its resting place the pill starts, so it appears to slide down
    /// out of the notch instead of popping into existence.
    private let entranceDrop: CGFloat = 14

    /// Entrance duration. Deliberately shorter than one countdown tick so the
    /// animation always finishes before the timer swaps rootView underneath it.
    private let entranceDuration: TimeInterval = 0.55

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

        // Live-activity entrance: the pill eases down out of the screen edge while it
        // fades up. Only the window origin moves — the size is fixed, so the
        // NSHostingView never re-lays-out mid-animation. AppKit-level only; SwiftUI
        // animations inside an NSHostingView overlay are not safe here.
        var startFrame = metrics.frame
        startFrame.origin.y += entranceDrop
        window.setFrame(startFrame, display: false)
        window.alphaValue = 0
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = entranceDuration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(metrics.frame, display: true)
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

        // NOTE: do NOT clear `onDismiss` here. `showNotch()` calls `hideNotch()` as its
        // first step, which runs *after* the caller has already installed the callback —
        // clearing it here left a live pill whose safety-timer failsafe fired into nil.
        // Reachable by sleeping mid-break and waking inside `sleepResetThreshold`.
        // GlimpseApp.hideNotch() clears it at the call site, which is the correct place.

        // 1. Stop all timers
        countdownTimer?.invalidate()
        countdownTimer = nil
        safetyTimer?.invalidate()
        safetyTimer = nil

        // 2. Disconnect SwiftUI view, hide window, drop reference
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

    /// The pill frame flush to the top of the active screen, plus the notch height
    /// (0 when the screen has no notch). Returns nil only if there is no screen at all.
    ///
    /// On a notched screen the pill is centered on the **notch**, not on the screen. Those
    /// are not the same point — the notch is typically offset from screen center by a point
    /// or two, and centering on the screen leaves the black shoulders visibly unequal.
    private func notchMetrics() -> (frame: NSRect, topInset: CGFloat)? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return nil }
        let inset = screen.safeAreaInsets.top
        let frame = Self.pillFrame(
            screenFrame: screen.frame,
            topInset: inset,
            auxTopLeft: screen.auxiliaryTopLeftArea,
            auxTopRight: screen.auxiliaryTopRightArea
        )
        return (frame, inset)
    }

    /// Pure geometry behind `notchMetrics()`, split out so it can be tested without a
    /// real notched screen. `auxTopLeft`/`auxTopRight` are the menu bar areas on either
    /// side of the notch, in the same coordinate space as `screenFrame`.
    static func pillFrame(
        screenFrame: NSRect,
        topInset inset: CGFloat,
        auxTopLeft: NSRect?,
        auxTopRight: NSRect?
    ) -> NSRect {
        let width: CGFloat
        let height: CGFloat
        let centerX: CGFloat

        if inset > 0, let auxLeft = auxTopLeft, let auxRight = auxTopRight {
            // Notched screen — derive the notch's true bounds, not just its width.
            let notchMinX = auxLeft.maxX
            let notchMaxX = auxRight.minX
            let notchWidth = max(0, notchMaxX - notchMinX)
            // Body clears the notch by the overhang; the window adds the cove on each side
            // (DynamicNotchKit: `minWidth = notchSize.width + topCornerRadius * 2`).
            width = notchWidth + Constants.notchBodyOverhang * 2
                + Constants.notchTopCornerRadius * 2
            height = inset + Constants.notchBodyHeight
            centerX = (notchMinX + notchMaxX) / 2
        } else {
            // No notch (or no aux areas to measure) — a top-center floating pill.
            // Taller than the notched body since there is no notch band above it.
            width = 260 + Constants.notchTopCornerRadius * 2
            height = 64
            centerX = screenFrame.midX
        }

        let x = centerX - width / 2
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
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
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        // We drive the entrance ourselves — keep AppKit from adding its own.
        window.animationBehavior = .none

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


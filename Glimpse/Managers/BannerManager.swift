//
//  BannerManager.swift
//  Glimpse
//
//  Creates and manages a small floating banner window that follows the cursor
//  during breaks. Uses the same snapshot/callback pattern as OverlayManager.
//
//  IMPORTANT: Window teardown must NOT call contentView=nil or close().
//  Instead, replace rootView with EmptyView, orderOut, and drop references.
//

import AppKit
import SwiftUI

/// NSWindow subclass that disables AppKit's automatic frame constraining.
/// Without this override, `setFrameOrigin` silently snaps the window back
/// onto visibleFrame, producing asymmetric clamping near screen edges.
private final class UnconstrainedWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

final class BannerManager {
    private var bannerWindow: NSWindow?
    private var countdownTimer: Timer?
    private var safetyTimer: Timer?
    private var displayLinkTimer: Timer?
    /// Snapshot values for rebuilding the view each tick
    private var currentSeconds: Int = 0
    private var overlayColor: Color = .clear

    /// Gap between cursor and banner edge
    private let cursorGap: CGFloat = 18

    /// Banner window size
    private let bannerSize = NSSize(width: 260, height: 110)

    /// Called when banner dismisses itself via safety timeout
    var onDismiss: (() -> Void)?

    // MARK: - Public

    /// Show the floating banner with the given snapshot values.
    func showBanner(initialSeconds: Int, overlayColor: Color) {
        DebugLog.log("BannerManager.showBanner() — initialSeconds=\(initialSeconds)")
        hideBanner()

        self.currentSeconds = initialSeconds
        self.overlayColor = overlayColor

        // Dismiss any open menu bar popover before showing banner
        for window in NSApp.windows where window is NSPanel {
            window.orderOut(nil)
        }

        let window = createBannerWindow()
        bannerWindow = window
        positionNearCursor(window)
        window.orderFront(nil)

        startCountdownTimer()
        startSafetyTimer()
        startPositionTimer()
        DebugLog.log("BannerManager.showBanner() — banner showing")
    }

    /// Hide the banner window and clean up all resources.
    func hideBanner() {
        guard bannerWindow != nil || countdownTimer != nil || safetyTimer != nil else { return }
        DebugLog.log("BannerManager.hideBanner()")

        // 1. Stop all timers and monitors
        countdownTimer?.invalidate()
        countdownTimer = nil
        stopSafetyTimer()
        stopPositionTimer()

        // 2. Disconnect SwiftUI view, hide window, drop reference
        if let window = bannerWindow {
            if let hostingView = window.contentView as? NSHostingView<AnyView> {
                hostingView.rootView = AnyView(EmptyView())
            }
            window.orderOut(nil)
        }
        bannerWindow = nil
    }

    /// Whether the banner is currently showing
    var isShowing: Bool {
        return bannerWindow != nil
    }

    // MARK: - Window Creation

    private func createBannerWindow() -> NSWindow {
        let window = UnconstrainedWindow(
            contentRect: NSRect(origin: .zero, size: bannerSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let view = makeBannerView()
        let hostingView = NSHostingView(rootView: AnyView(view))
        hostingView.frame = NSRect(origin: .zero, size: bannerSize)
        window.contentView = hostingView

        return window
    }

    private func makeBannerView() -> BannerView {
        BannerView(
            seconds: currentSeconds,
            overlayColor: overlayColor
        )
    }

    // MARK: - Positioning

    /// Position the banner centered horizontally on the cursor, just below it.
    /// Clamped only as a safety net so the banner can't leave the visible frame.
    private func positionNearCursor(_ window: NSWindow) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
            ?? NSScreen.main
        let bounds = screen?.frame ?? .zero

        let rawX = mouse.x - bannerSize.width / 2
        let rawY = mouse.y - cursorGap - bannerSize.height

        let x = min(max(rawX, bounds.minX), bounds.maxX - bannerSize.width)
        let y = min(max(rawY, bounds.minY), bounds.maxY - bannerSize.height)

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        let timer = Timer(timeInterval: Constants.timerTickInterval, repeats: true) { [weak self] timer in
            guard let self, self.bannerWindow != nil else {
                timer.invalidate()
                return
            }
            self.currentSeconds = max(0, self.currentSeconds - 1)
            if self.currentSeconds <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                return
            }
            self.updateBannerView()
        }
        countdownTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func updateBannerView() {
        let view = makeBannerView()
        if let window = bannerWindow,
           let hostingView = window.contentView as? NSHostingView<AnyView> {
            hostingView.rootView = AnyView(view)
        }
    }

    // MARK: - Safety Timer

    private func startSafetyTimer() {
        let duration = TimeInterval(currentSeconds) + 5
        let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
            guard let self, self.isShowing else { return }
            DebugLog.log("BannerManager: safetyTimer FIRED — calling onDismiss")
            self.onDismiss?()
        }
        safetyTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func stopSafetyTimer() {
        safetyTimer?.invalidate()
        safetyTimer = nil
    }

    // MARK: - Position Timer

    /// Polls cursor position at ~60fps using a lightweight timer.
    /// Much cheaper than a global NSEvent monitor which fires on every mouse event.
    private func startPositionTimer() {
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self, let window = self.bannerWindow else {
                timer.invalidate()
                return
            }
            self.positionNearCursor(window)
        }
        displayLinkTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func stopPositionTimer() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
    }
}

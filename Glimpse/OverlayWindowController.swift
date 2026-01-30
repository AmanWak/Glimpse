//
//  OverlayWindowController.swift
//  Glimpse
//
//  Full-screen overlay window for break reminders
//

import Cocoa
import SwiftUI

class OverlayWindowController: NSWindowController {
    var onSkip: ((Bool) -> Void)?
    var onComplete: (() -> Void)?
    
    private var overlayWindows: [NSWindow] = []
    private var timer: Timer?
    private var countdown: Int = 20
    private var message: String = ""
    private var hostingControllers: [NSHostingController<OverlayView>] = []
    
    init() {
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showOverlay() {
        // Close existing windows
        close()
        
        // Get all screens for multi-monitor support
        let screens = NSScreen.screens
        
        // Get a random message for this break
        message = MessageProvider.randomMessage()
        
        // Create windows for each screen
        for screen in screens {
            let window = createOverlayWindow(for: screen)
            window.makeKeyAndOrderFront(nil)
            overlayWindows.append(window)
        }
        
        // Start countdown
        countdown = 20
        startCountdown()
        
        // Activate app to bring overlay to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let overlayView = OverlayView(
            countdown: countdown,
            message: message,
            onSkip: { [weak self] in
                self?.handleSkip()
            }
        )
        
        let controller = NSHostingController(rootView: overlayView)
        hostingControllers.append(controller)
        
        let window = NSWindow(contentViewController: controller)
        window.setFrame(screen.frame, display: true)
        window.styleMask = [.borderless, .fullSizeContentView]
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        
        return window
    }
    
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.countdown -= 1
            self.updateOverlay()
            
            if self.countdown <= 0 {
                self.timer?.invalidate()
                self.onComplete?()
            }
        }
    }
    
    private func updateOverlay() {
        // Update all hosting controllers with new countdown
        for controller in hostingControllers {
            controller.rootView = OverlayView(
                countdown: countdown,
                message: message,
                onSkip: { [weak self] in
                    self?.handleSkip()
                }
            )
        }
    }
    
    private func handleSkip() {
        timer?.invalidate()
        
        // Check if we should show confirmation
        if StreakTracker.shared.shouldShowSkipConfirmation {
            showSkipConfirmation()
        } else {
            onSkip?(true)
        }
    }
    
    private func showSkipConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Skip this break?"
        alert.informativeText = "You've skipped the last 2 breaks. Are you sure you want to skip again?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Continue Break")
        alert.addButton(withTitle: "Skip Anyway")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            onSkip?(true)
        } else {
            // Resume countdown
            startCountdown()
        }
    }
    
    override func close() {
        timer?.invalidate()
        timer = nil
        
        // Close all overlay windows
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
        hostingControllers.removeAll()
    }
}

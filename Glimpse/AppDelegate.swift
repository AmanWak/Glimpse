//
//  AppDelegate.swift
//  Glimpse
//
//  Menu bar lifecycle management for the 20-20-20 eye break reminder app
//

import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var timerManager: TimerManager?
    var overlayWindowController: OverlayWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        GlimpseLogger.log("Application launching", log: .app)
        
        // Hide dock icon - menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        // Set up menu bar status item
        setupMenuBar()
        
        // Initialize timer manager
        timerManager = TimerManager()
        timerManager?.delegate = self
        
        // Request notification permissions and set up categories
        requestNotificationPermissions()
        NotificationManager.shared.setupNotificationCategories()
        
        // Start the 20-minute timer
        timerManager?.start()
        
        GlimpseLogger.log("Application launched successfully", log: .app)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Glimpse")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    @objc private func togglePopover() {
        if let popover = popover, popover.isShown {
            popover.close()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        
        if popover == nil {
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 280, height: 320)
            popover?.behavior = .transient
            popover?.contentViewController = NSHostingController(rootView: MenuBarPopoverView(
                timerManager: timerManager,
                onSkipToBreak: { [weak self] in
                    self?.timerManager?.triggerBreakNow()
                },
                onTogglePause: { [weak self] in
                    self?.timerManager?.togglePause()
                },
                onOpenSettings: { [weak self] in
                    self?.openSettings()
                }
            ))
        }
        
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    private func openSettings() {
        // Close popover
        popover?.close()
        
        // Open settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Glimpse Settings"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                GlimpseLogger.error("Error requesting notification permissions", log: .notifications, error: error)
            } else if granted {
                GlimpseLogger.log("Notification permissions granted", log: .notifications)
            } else {
                GlimpseLogger.log("Notification permissions denied", log: .notifications, type: .info)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        GlimpseLogger.log("Application terminating", log: .app)
        timerManager?.stop()
    }
}

// MARK: - TimerManagerDelegate
extension AppDelegate: TimerManagerDelegate {
    func timerManagerDidTriggerBreak(_ manager: TimerManager) {
        showOverlay()
    }
    
    func timerManagerDidUpdate(_ manager: TimerManager) {
        // Update menu bar icon if paused
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: manager.isPaused ? "eye.slash" : "eye", 
                                   accessibilityDescription: "Glimpse")
        }
    }
    
    private func showOverlay() {
        // Close popover if open
        popover?.close()
        
        // Check break style preference
        if SettingsManager.shared.breakStyle == .notification {
            // Use notification fallback
            NotificationManager.shared.sendBreakNotification()
            
            // Auto-complete break after 20 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
                self?.timerManager?.completeBreak(userSkipped: false)
            }
            return
        }
        
        // Create or reuse overlay window controller
        if overlayWindowController == nil {
            overlayWindowController = OverlayWindowController()
            overlayWindowController?.onSkip = { [weak self] userSkipped in
                self?.timerManager?.completeBreak(userSkipped: userSkipped)
                self?.overlayWindowController?.close()
            }
            overlayWindowController?.onComplete = { [weak self] in
                self?.timerManager?.completeBreak(userSkipped: false)
                self?.overlayWindowController?.close()
            }
        }
        
        overlayWindowController?.showOverlay()
    }
}

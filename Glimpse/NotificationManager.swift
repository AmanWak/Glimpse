//
//  NotificationManager.swift
//  Glimpse
//
//  Manages system notifications as fallback for overlay
//

import Foundation
import UserNotifications

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        setupNotificationCenter()
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func sendBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for a break!"
        content.body = MessageProvider.randomMessage()
        content.sound = .default
        content.categoryIdentifier = "BREAK_REMINDER"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                GlimpseLogger.error("Error sending notification", log: .notifications, error: error)
            } else {
                GlimpseLogger.log("Break notification sent", log: .notifications)
            }
        }
    }
    
    func setupNotificationCategories() {
        let skipAction = UNNotificationAction(
            identifier: "SKIP_ACTION",
            title: "Skip",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "BREAK_REMINDER",
            actions: [skipAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is active
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "SKIP_ACTION" {
            // User skipped via notification
            StreakTracker.shared.recordSkip()
        }
        
        completionHandler()
    }
}

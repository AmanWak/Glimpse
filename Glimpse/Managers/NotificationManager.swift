//
//  NotificationManager.swift
//  Glimpse
//
//  Handles system notifications as fallback when overlay is blocked.
//

import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    /// Request notification permissions
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    /// Show a break notification
    func showBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for an Eye Break"
        content.body = Messages.random()
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error.localizedDescription)")
            }
        }
    }

    /// Show break completion notification
    func showBreakCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break Complete"
        content.body = "Great job! Your eyes thank you."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error.localizedDescription)")
            }
        }
    }

    /// Remove all pending notifications
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

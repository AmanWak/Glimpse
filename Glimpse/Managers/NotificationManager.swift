//
//  NotificationManager.swift
//  Glimpse
//
//  Handles system notifications as fallback when overlay is blocked.
//

import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    /// Set up the notification center delegate so notifications display while app is active
    func setupDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Request notification permissions. Safe to call multiple times —
    /// only shows the system dialog when status is `.notDetermined`.
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DebugLog.log("NotificationManager: requestAuthorization granted=\(granted)")
            if let error = error {
                DebugLog.log("NotificationManager: permission error — \(error.localizedDescription)")
            }
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    /// Show a break notification (checks authorization first)
    func showBreakNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                DebugLog.log("NotificationManager: cannot show notification — status=\(settings.authorizationStatus.rawValue)")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Time for an Eye Break"
            content.body = Messages.random()
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            center.add(request) { error in
                if let error = error {
                    DebugLog.log("NotificationManager: failed to show — \(error.localizedDescription)")
                }
            }
        }
    }

    /// Show break completion notification
    func showBreakCompleteNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "Break Complete"
            content.body = "Great job! Your eyes thank you."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            center.add(request) { error in
                if let error = error {
                    DebugLog.log("NotificationManager: failed to show — \(error.localizedDescription)")
                }
            }
        }
    }

    /// Remove all pending notifications
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notifications even when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}

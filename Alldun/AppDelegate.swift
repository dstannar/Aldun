import UIKit
import UserNotifications
import SwiftUI // For Notification.Name extension or potential future use

// Copied from AlldunApp.swift
extension Notification.Name {
    static let didRequestTaskOpen = Notification.Name("didRequestTaskOpen")
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        print("AppDelegate: Application didFinishLaunchingWithOptions. UNUserNotificationCenter delegate set.")
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let identifier = notification.request.identifier
        print("AppDelegate: Notification will be presented while app is in foreground for identifier: \(identifier)")
        
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let rawIdentifier = response.notification.request.identifier
        print("AppDelegate: User tapped on notification with raw identifier: \(rawIdentifier)")

        // Extract base Task ID and notification type
        var taskIDString: String?
        if rawIdentifier.hasSuffix("_start") {
            taskIDString = String(rawIdentifier.dropLast("_start".count))
        } else if rawIdentifier.hasSuffix("_due") {
            taskIDString = String(rawIdentifier.dropLast("_due".count))
        } else {
            // Fallback for old identifiers or other notifications not following the new pattern
            taskIDString = rawIdentifier
        }
        
        let notificationType = userInfo["notificationType"] as? String

        if let idStr = taskIDString, let taskID = UUID(uuidString: idStr) {
            var notificationData: [AnyHashable: Any] = ["taskID": taskID]
            if let type = notificationType {
                notificationData["notificationType"] = type
            }
            print("AppDelegate: Posting .didRequestTaskOpen notification for taskID: \(taskID), type: \(notificationType ?? "unknown")")
            NotificationCenter.default.post(name: .didRequestTaskOpen, object: nil, userInfo: notificationData)
        } else {
            print("AppDelegate: Could not convert base identifier part to UUID: \(taskIDString ?? "nil") from raw: \(rawIdentifier)")
        }

        completionHandler()
    }
}

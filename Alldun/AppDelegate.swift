
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
        
        let taskID = notification.request.identifier
        print("AppDelegate: Notification will be presented while app is in foreground for task ID: \(taskID)")
        
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let taskIDString = response.notification.request.identifier
        print("AppDelegate: User tapped on notification for task ID string: \(taskIDString)")
        
        if let taskID = UUID(uuidString: taskIDString) {
            print("AppDelegate: Posting .didRequestTaskOpen notification for taskID: \(taskID)")
            NotificationCenter.default.post(name: .didRequestTaskOpen, object: nil, userInfo: ["taskID": taskID])
        } else {
            print("AppDelegate: Could not convert identifier to UUID: \(taskIDString)")
        }

        completionHandler()
    }
}
// End of file

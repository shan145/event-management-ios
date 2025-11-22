//
//  EventableApp.swift
//  Eventable
//
//  Created by Samuel Han on 8/30/25.
//

import SwiftUI
import UserNotifications

@main
struct EventableApp: App {
    @StateObject private var authManager = AuthManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(.light) // Force light mode to match web app
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        
        Task { @MainActor in
            NavigationCoordinator.shared.handleDeepLink(url)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device token received: \(tokenString)")
        
        // Only register device token if user is authenticated
        // The token will be registered after login/signup
        if AuthManager.shared.isAuthenticated {
            NotificationService.shared.setDeviceToken(tokenString)
        } else {
            // Store token temporarily, will be registered after login
            NotificationService.shared.storeDeviceTokenForLater(tokenString)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle deep linking based on notification data
        if let deepLink = userInfo["deepLink"] as? String {
            handleDeepLink(deepLink)
        } else if let type = userInfo["type"] as? String {
            handleNotificationType(type, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleDeepLink(_ deepLink: String) {
        print("🔗 Handling deep link: \(deepLink)")
        // Implement deep linking logic here
        // This could navigate to specific screens based on the deep link
    }
    
    private func handleNotificationType(_ type: String, userInfo: [AnyHashable: Any]) {
        print("📱 Handling notification type: \(type)")
        
        switch type {
        case "event_invite", "event_reminder", "event_update":
            if let eventId = userInfo["eventId"] as? String {
                // Navigate to event details
                print("🎉 Navigate to event: \(eventId)")
            }
        case "group_invite", "group_update":
            if let groupId = userInfo["groupId"] as? String {
                // Navigate to group details
                print("👥 Navigate to group: \(groupId)")
            }
        default:
            // Navigate to notifications screen
            print("📋 Navigate to notifications")
        }
    }
}

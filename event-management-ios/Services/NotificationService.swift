import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let apiService = APIService.shared
    private var realTimeTimer: Timer?
    
    private init() {
        checkAuthorizationStatus()
        // fetchNotifications() will be called when needed, not in init
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }
        }
    }
    
    private func registerForRemoteNotifications() async {
        // Register for remote notifications
        // This would typically be handled by the app delegate
        print("Registered for remote notifications")
    }
    
    // MARK: - Local Notifications
    
    func scheduleEventReminder(event: Event, minutesBefore: Int = 30) {
        guard let eventDate = ISO8601DateFormatter().date(from: event.date) else { return }
        
        let reminderDate = eventDate.addingTimeInterval(-TimeInterval(minutesBefore * 60))
        
        let content = UNMutableNotificationContent()
        content.title = "Event Reminder"
        content.body = "Your event '\(event.title)' starts in \(minutesBefore) minutes"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["eventId": event.id, "type": "event_reminder"]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "event-reminder-\(event.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func scheduleGroupInviteNotification(groupName: String, inviterName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Group Invitation"
        content.body = "\(inviterName) invited you to join '\(groupName)'"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "group_invite"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "group-invite-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule group invite notification: \(error)")
            }
        }
    }
    
    func scheduleEventUpdateNotification(eventTitle: String, updateType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Event Update"
        content.body = "Your event '\(eventTitle)' has been \(updateType)"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "event_update"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "event-update-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule event update notification: \(error)")
            }
        }
    }
    
    func scheduleAttendeeStatusNotification(eventTitle: String, attendeeName: String, status: String) {
        let content = UNMutableNotificationContent()
        content.title = "Attendee Update"
        content.body = "\(attendeeName) is now \(status) for '\(eventTitle)'"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "attendee_status"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "attendee-status-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule attendee status notification: \(error)")
            }
        }
    }
    
    func cancelEventReminder(eventId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event-reminder-\(eventId)"])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // MARK: - In-App Notifications
    
    func fetchNotifications() async {
        do {
            let response = try await apiService.getNotifications()
            await MainActor.run {
                self.notifications = response.data.notifications
                self.updateUnreadCount()
            }
        } catch {
            print("Failed to fetch notifications: \(error)")
        }
    }
    
    func markNotificationAsRead(notificationId: String) async {
        do {
            _ = try await apiService.markNotificationAsRead(notificationId: notificationId)
            await fetchNotifications()
        } catch {
            print("Failed to mark notification as read: \(error)")
        }
    }
    
    func markAllNotificationsAsRead() async {
        do {
            _ = try await apiService.markAllNotificationsAsRead()
            await fetchNotifications()
        } catch {
            print("Failed to mark all notifications as read: \(error)")
        }
    }
    
    // MARK: - Real-time Updates
    
    func startRealTimeUpdates() {
        stopRealTimeUpdates() // Stop any existing timer
        
        // Poll for new notifications every 30 seconds
        realTimeTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.fetchNotifications()
            }
        }
    }
    
    func stopRealTimeUpdates() {
        realTimeTimer?.invalidate()
        realTimeTimer = nil
    }
    
    // MARK: - Helper Methods
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    func getNotificationBadgeCount() -> Int {
        return unreadCount
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let eventReminderCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_EVENT",
                    title: "View Event",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: "Snooze 15 min",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let groupInviteCategory = UNNotificationCategory(
            identifier: "GROUP_INVITE",
            actions: [
                UNNotificationAction(
                    identifier: "ACCEPT_INVITE",
                    title: "Accept",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DECLINE_INVITE",
                    title: "Decline",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            eventReminderCategory,
            groupInviteCategory
        ])
    }
}

// MARK: - App Notification Model

struct AppNotification: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let data: NotificationData?
    
    var formattedDate: String {
        // Format the date for display
        if let date = ISO8601DateFormatter().date(from: createdAt) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return createdAt
    }
}

enum NotificationType: String, Codable {
    case eventInvite = "event_invite"
    case eventReminder = "event_reminder"
    case eventUpdate = "event_update"
    case eventCancelled = "event_cancelled"
    case groupInvite = "group_invite"
    case groupUpdate = "group_update"
    case attendeeJoined = "attendee_joined"
    case attendeeLeft = "attendee_left"
    case waitlistPromoted = "waitlist_promoted"
    case general = "general"
}

struct NotificationData: Codable {
    let eventId: String?
    let groupId: String?
    let userId: String?
    let actionUrl: String?
}

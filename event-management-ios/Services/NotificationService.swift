import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var notifications: [AppNotification] = []
    
    private let apiService = APIService.shared
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
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
                self.isAuthorized = settings.authorizationStatus == .authorized
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
    
    func cancelEventReminder(eventId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event-reminder-\(eventId)"])
    }
    
    // MARK: - In-App Notifications
    
    func fetchNotifications() async {
        do {
            let response = try await apiService.getNotifications()
            await MainActor.run {
                self.notifications = response.data.notifications
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
        // Start WebSocket connection or polling for real-time updates
        // This would typically connect to a WebSocket server
        print("Started real-time updates")
    }
    
    func stopRealTimeUpdates() {
        // Stop WebSocket connection or polling
        print("Stopped real-time updates")
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

import Foundation
import SwiftUI

@MainActor
class PreferencesSettingsViewModel: ObservableObject {
    // Email Notification Preferences
    @Published var emailNotificationsEnabled = true
    
    // Push Notification Preferences
    @Published var pushEventInvites = true
    @Published var pushEventReminders = true
    @Published var pushEventUpdates = true
    @Published var pushEventCancellations = true
    @Published var pushGroupInvites = true
    @Published var pushGroupUpdates = true
    @Published var pushSystemAnnouncements = true
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var hasLoaded = false
    
    private let apiService = APIService.shared
    
    func loadPreferences() async {
        if hasLoaded { return }
        await refreshPreferences()
        hasLoaded = true
    }
    
    func refreshPreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getNotificationPreferences()
            apply(preferences: response.data.preferences)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func savePreferences() async {
        isLoading = true
        errorMessage = nil
        showSuccess = false
        
        let pushPreferences = NotificationPreferenceTypesDTO(
            eventInvites: pushEventInvites,
            eventReminders: pushEventReminders,
            eventUpdates: pushEventUpdates,
            eventCancellations: pushEventCancellations,
            groupInvites: pushGroupInvites,
            groupUpdates: pushGroupUpdates,
            systemAnnouncements: pushSystemAnnouncements
        )
        
        let request = UpdateNotificationPreferencesRequest(
            preferences: NotificationPreferencesDTO(
                email: emailNotificationsEnabled ? nil : NotificationPreferenceTypesDTO(
                    eventInvites: false,
                    eventReminders: false,
                    eventUpdates: false,
                    eventCancellations: false,
                    groupInvites: false,
                    groupUpdates: false,
                    systemAnnouncements: false
                ),
                push: pushPreferences,
                reminderTiming: nil
            )
        )
        
        do {
            _ = try await apiService.updateNotificationPreferences(preferences: request)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func apply(preferences: NotificationPreferencesDTO) {
        // Email
        if let email = preferences.email {
            emailNotificationsEnabled = ![
                email.eventInvites,
                email.eventReminders,
                email.eventUpdates,
                email.eventCancellations,
                email.groupInvites,
                email.groupUpdates,
                email.systemAnnouncements
            ].contains(false)
        } else {
            emailNotificationsEnabled = true
        }
        
        // Push
        pushEventInvites = preferences.push.eventInvites ?? true
        pushEventReminders = preferences.push.eventReminders ?? true
        pushEventUpdates = preferences.push.eventUpdates ?? true
        pushEventCancellations = preferences.push.eventCancellations ?? true
        pushGroupInvites = preferences.push.groupInvites ?? true
        pushGroupUpdates = preferences.push.groupUpdates ?? true
        pushSystemAnnouncements = preferences.push.systemAnnouncements ?? true
    }
}

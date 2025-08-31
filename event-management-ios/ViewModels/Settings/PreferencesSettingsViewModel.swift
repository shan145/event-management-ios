import Foundation
import SwiftUI

@MainActor
class PreferencesSettingsViewModel: ObservableObject {
    // Notification Preferences
    @Published var eventReminders = true
    @Published var groupUpdates = true
    @Published var emailNotifications = true
    @Published var pushNotifications = true
    
    // Privacy Settings
    @Published var showProfileToOthers = true
    @Published var allowEventInvites = true
    @Published var showEmailToGroupMembers = false
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let apiService = APIService.shared
    
    func loadPreferences() {
        // Load preferences from UserDefaults or API
        // For now, we'll use default values
        // TODO: Implement actual preference loading from backend
    }
    
    func savePreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let preferences = UserPreferences(
                eventReminders: eventReminders,
                groupUpdates: groupUpdates,
                emailNotifications: emailNotifications,
                pushNotifications: pushNotifications,
                showProfileToOthers: showProfileToOthers,
                allowEventInvites: allowEventInvites,
                showEmailToGroupMembers: showEmailToGroupMembers
            )
            
            let response = try await apiService.updatePreferences(preferences: preferences)
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - User Preferences Model

struct UserPreferences: Codable {
    let eventReminders: Bool
    let groupUpdates: Bool
    let emailNotifications: Bool
    let pushNotifications: Bool
    let showProfileToOthers: Bool
    let allowEventInvites: Bool
    let showEmailToGroupMembers: Bool
}

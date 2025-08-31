import Foundation
import SwiftUI

@MainActor
class ProfileSettingsViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let apiService = APIService.shared
    
    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func loadUserProfile() {
        guard let currentUser = AuthManager.shared.currentUser else { return }
        
        firstName = currentUser.firstName
        lastName = currentUser.lastName
        email = currentUser.email
    }
    
    func updateProfile() async {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.updateProfile(
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // Update the current user in AuthManager
            AuthManager.shared.currentUser = response.data.user
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

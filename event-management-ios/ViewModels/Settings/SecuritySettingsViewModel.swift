import Foundation
import SwiftUI

@MainActor
class SecuritySettingsViewModel: ObservableObject {
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let apiService = APIService.shared
    
    var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6
    }
    
    func updatePassword() async {
        guard isValid else {
            if currentPassword.isEmpty {
                errorMessage = "Please enter your current password"
            } else if newPassword.isEmpty {
                errorMessage = "Please enter a new password"
            } else if confirmPassword.isEmpty {
                errorMessage = "Please confirm your new password"
            } else if newPassword != confirmPassword {
                errorMessage = "New passwords do not match"
            } else if newPassword.count < 6 {
                errorMessage = "Password must be at least 6 characters long"
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func clearForm() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
    }
}

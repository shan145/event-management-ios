import Foundation
import SwiftUI

@MainActor
class DeleteAccountViewModel: ObservableObject {
    @Published var currentPassword = ""
    @Published var confirmationEmail = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    func canSubmit(expectedEmail: String) -> Bool {
        let trimmedEmail = confirmationEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedExpected = expectedEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return !currentPassword.isEmpty &&
        !trimmedEmail.isEmpty &&
        trimmedEmail == trimmedExpected
    }
    
    func deleteAccount(using authManager: AuthManager) async -> Bool {
        guard let email = authManager.currentUser?.email, !email.isEmpty else {
            errorMessage = "Unable to load account information."
            return false
        }
        
        guard canSubmit(expectedEmail: email) else {
            errorMessage = "Please enter your email exactly to confirm."
            return false
        }
        
        isProcessing = true
        errorMessage = nil
        
        let success = await authManager.deleteAccount(currentPassword: currentPassword)
        if !success {
            errorMessage = authManager.errorMessage ?? "Failed to delete account. Please try again."
        }
        
        isProcessing = false
        return success
    }
    
    func reset() {
        currentPassword = ""
        confirmationEmail = ""
        errorMessage = nil
    }
}


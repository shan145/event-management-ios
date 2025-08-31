import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let keychain = KeychainService()
    
    private init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        guard let token = keychain.getToken() else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        apiService.setAuthToken(token)
        
        do {
            let response = try await apiService.getCurrentUser()
            currentUser = response.data.user
            isAuthenticated = true
        } catch {
            await logout()
        }
    }
    
    func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.login(email: email, password: password)
            currentUser = response.data.user
            apiService.setAuthToken(response.data.token)
            keychain.saveToken(response.data.token)
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signup(firstName: String, lastName: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.signup(firstName: firstName, lastName: lastName, email: email, password: password)
            currentUser = response.data.user
            apiService.setAuthToken(response.data.token)
            keychain.saveToken(response.data.token)
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func createAdmin(firstName: String, lastName: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.createAdmin(firstName: firstName, lastName: lastName, email: email, password: password)
            currentUser = response.data.user
            apiService.setAuthToken(response.data.token)
            keychain.saveToken(response.data.token)
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func logout() async {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        apiService.clearAuthToken()
        keychain.deleteToken()
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Keychain Service

class KeychainService {
    private let service = "com.eventmanagement.ios"
    private let account = "authToken"
    
    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

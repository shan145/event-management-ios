import Foundation
import SwiftUI
import LocalAuthentication

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isBiometricLoginEnabled = false
    
    private let apiService = APIService.shared
    private let keychain = KeychainService()
    private let biometricAuthService = BiometricAuthService()
    private let biometricLoginEnabledKey = "biometricLoginEnabled"
    
    private init() {
        isBiometricLoginEnabled = UserDefaults.standard.bool(forKey: biometricLoginEnabledKey)
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
        
        if isBiometricLoginEnabled && biometricAuthService.isAvailable {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        apiService.setAuthToken(token)
        
        do {
            let response = try await apiService.getCurrentUser()
            currentUser = response.data.user
            isAuthenticated = true
            
            // Register device token if user is already authenticated
            NotificationService.shared.registerPendingDeviceToken()
        } catch {
            await logout()
        }
    }
    
    var canUseBiometricLogin: Bool {
        biometricAuthService.isAvailable && keychain.getToken() != nil
    }
    
    var biometricDisplayName: String {
        biometricAuthService.displayName
    }
    
    func setBiometricLoginEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            guard biometricAuthService.isAvailable else {
                errorMessage = "Biometric authentication is not available on this device."
                return false
            }
            
            do {
                _ = try await biometricAuthService.authenticate(reason: "Enable \(biometricAuthService.displayName) login")
                isBiometricLoginEnabled = true
                UserDefaults.standard.set(true, forKey: biometricLoginEnabledKey)
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        } else {
            isBiometricLoginEnabled = false
            UserDefaults.standard.set(false, forKey: biometricLoginEnabledKey)
            return true
        }
    }
    
    func loginWithBiometrics() async -> Bool {
        guard let token = keychain.getToken() else {
            errorMessage = "No saved session found. Please sign in with email and password first."
            return false
        }
        
        guard biometricAuthService.isAvailable else {
            errorMessage = "Biometric authentication is not available on this device."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await biometricAuthService.authenticate(reason: "Sign in to your account")
            apiService.setAuthToken(token)
            let response = try await apiService.getCurrentUser()
            currentUser = response.data.user
            isAuthenticated = true
            isLoading = false
            NotificationService.shared.registerPendingDeviceToken()
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
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
            
            // Register device token after successful login
            NotificationService.shared.registerPendingDeviceToken()
            
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
            
            // Register device token after successful signup
            NotificationService.shared.registerPendingDeviceToken()
            
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
    
    func deleteAccount(currentPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiService.deleteAccount(currentPassword: currentPassword)
            await logout()
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
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

enum BiometricAuthError: LocalizedError {
    case unavailable
    case failed
    
    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Biometric authentication is unavailable."
        case .failed:
            return "Biometric authentication failed. Please try again."
        }
    }
}

class BiometricAuthService {
    private var context: LAContext {
        LAContext()
    }
    
    var isAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var displayName: String {
        var error: NSError?
        let localContext = context
        _ = localContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch localContext.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometrics"
        }
    }
    
    func authenticate(reason: String) async throws -> Bool {
        let localContext = context
        var error: NSError?
        
        guard localContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricAuthError.unavailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            localContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
                if let evalError = evalError {
                    continuation.resume(throwing: evalError)
                    return
                }
                
                if success {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(throwing: BiometricAuthError.failed)
                }
            }
        }
    }
}

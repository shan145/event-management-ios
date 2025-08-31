import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.md) {
                Text("Welcome Back")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                
                Text("Sign in to your account")
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextSecondary)
            }
            
            VStack(spacing: AppSpacing.md) {
                AppTextField(
                    title: "Email",
                    placeholder: "Enter your email",
                    text: $email,
                    validation: validateEmail
                )
                
                AppTextField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: $password,
                    isSecure: true,
                    validation: validatePassword
                )
            }
            
            AppButton(
                title: "Sign In",
                action: handleLogin,
                isLoading: isLoading
            )
            
            Button("Forgot your password?") {
                showingForgotPassword = true
            }
            .buttonStyle(TextButtonStyle())
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private func handleLogin() {
        guard !email.isEmpty && !password.isEmpty else { return }
        
        isLoading = true
        
        Task {
            let success = await authManager.login(email: email, password: password)
            isLoading = false
            
            if !success {
                // Error is handled by AuthManager and shown in alert
            }
        }
    }
    
    private func validateEmail(_ email: String) -> String? {
        if email.isEmpty {
            return "Email is required"
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            return "Please enter a valid email address"
        }
        
        return nil
    }
    
    private func validatePassword(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        
        if password.count < 6 {
            return "Password must be at least 6 characters"
        }
        
        return nil
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}

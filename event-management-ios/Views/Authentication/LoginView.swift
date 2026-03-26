import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingForgotPassword = false
    @State private var biometricToggle = false
    @State private var isUpdatingBiometricToggle = false
    @State private var hasInitializedBiometricToggle = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Welcome section
            VStack(spacing: AppSpacing.md) {
                Text("Welcome back")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                    .fontWeight(.bold)
                
                Text("Sign in to your account to continue")
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Form section
            VStack(spacing: AppSpacing.lg) {
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
                    title: "Sign in",
                    action: handleLogin,
                    isLoading: isLoading
                )

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Toggle("Enable \(authManager.biometricDisplayName) to sign in", isOn: $biometricToggle)
                        .disabled(isUpdatingBiometricToggle)
                    
                    if !authManager.canUseBiometricLogin {
                        Text("You must sign in once with email and password before enabling biometric sign-in.")
                            .font(AppTypography.caption)
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
                .padding(.top, AppSpacing.sm)
                
                if authManager.isBiometricLoginEnabled {
                    AppButton(
                        title: "Sign in with \(authManager.biometricDisplayName)",
                        action: handleBiometricLogin,
                        style: .secondary,
                        isLoading: isLoading,
                        isDisabled: !authManager.canUseBiometricLogin,
                        icon: authManager.biometricDisplayName == "Face ID" ? "faceid" : "touchid"
                    )
                }
                
                Button("Forgot your password?") {
                    showingForgotPassword = true
                }
                .buttonStyle(TextButtonStyle())
            }
            
            Spacer()
            
            // Sign up link removed - handled by parent AuthenticationView
        }
        .padding(.horizontal, AppSpacing.xl)
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
        .onAppear {
            biometricToggle = authManager.isBiometricLoginEnabled
            hasInitializedBiometricToggle = true
        }
        .onChange(of: biometricToggle) { oldValue, newValue in
            guard hasInitializedBiometricToggle, oldValue != newValue else { return }
            isUpdatingBiometricToggle = true
            
            Task {
                let success = await authManager.setBiometricLoginEnabled(newValue)
                if !success {
                    biometricToggle = oldValue
                }
                
                isUpdatingBiometricToggle = false
            }
        }
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
    
    private func handleBiometricLogin() {
        isLoading = true
        
        Task {
            _ = await authManager.loginWithBiometrics()
            isLoading = false
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Title section
            VStack(spacing: AppSpacing.sm) {
                Text("Create your account")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                    .fontWeight(.bold)
                
                Text("Get started with Eventify today")
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Form section
            VStack(spacing: AppSpacing.lg) {
                VStack(spacing: AppSpacing.md) {
                    AppTextField(
                        title: "First Name",
                        placeholder: "Enter your first name",
                        text: $firstName,
                        validation: validateFirstName
                    )
                    
                    AppTextField(
                        title: "Last Name",
                        placeholder: "Enter your last name",
                        text: $lastName,
                        validation: validateLastName
                    )
                    
                    AppTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $email,
                        validation: validateEmail
                    )
                    
                    AppTextField(
                        title: "Password",
                        placeholder: "Create a password",
                        text: $password,
                        isSecure: true,
                        validation: validatePassword
                    )
                    
                    AppTextField(
                        title: "Confirm Password",
                        placeholder: "Confirm your password",
                        text: $confirmPassword,
                        isSecure: true,
                        validation: validateConfirmPassword
                    )
                }
                
                AppButton(
                    title: "Create account",
                    action: handleSignup,
                    isLoading: isLoading
                )
            }
            
            Spacer()
            
            // Sign in link removed - handled by parent AuthenticationView
        }
        .padding(.horizontal, AppSpacing.xl)
    }
    
    private func handleSignup() {
        guard validateForm() else { return }
        
        isLoading = true
        
        Task {
            let success = await authManager.signup(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
            isLoading = false
            
            if !success {
                // Error is handled by AuthManager and shown in alert
            }
        }
    }
    
    private func validateForm() -> Bool {
        return validateFirstName(firstName) == nil &&
               validateLastName(lastName) == nil &&
               validateEmail(email) == nil &&
               validatePassword(password) == nil &&
               validateConfirmPassword(confirmPassword) == nil
    }
    
    private func validateFirstName(_ firstName: String) -> String? {
        if firstName.isEmpty {
            return "First name is required"
        }
        
        if firstName.count > 50 {
            return "First name must be less than 50 characters"
        }
        
        return nil
    }
    
    private func validateLastName(_ lastName: String) -> String? {
        if lastName.isEmpty {
            return "Last name is required"
        }
        
        if lastName.count > 50 {
            return "Last name must be less than 50 characters"
        }
        
        return nil
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
    
    private func validateConfirmPassword(_ confirmPassword: String) -> String? {
        if confirmPassword.isEmpty {
            return "Please confirm your password"
        }
        
        if confirmPassword != password {
            return "Passwords do not match"
        }
        
        return nil
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthManager.shared)
}

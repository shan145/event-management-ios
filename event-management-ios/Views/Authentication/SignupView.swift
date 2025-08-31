import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showAdminCreation = false
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.md) {
                Text("Create Account")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                
                Text("Join us to start managing events")
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextSecondary)
            }
            
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.md) {
                    AppTextField(
                        title: "First Name",
                        placeholder: "Enter first name",
                        text: $firstName,
                        validation: validateFirstName
                    )
                    
                    AppTextField(
                        title: "Last Name",
                        placeholder: "Enter last name",
                        text: $lastName,
                        validation: validateLastName
                    )
                }
                
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
                
                AppTextField(
                    title: "Confirm Password",
                    placeholder: "Confirm your password",
                    text: $confirmPassword,
                    isSecure: true,
                    validation: validateConfirmPassword
                )
            }
            
            AppButton(
                title: "Create Account",
                action: handleSignup,
                isLoading: isLoading
            )
            
            Button("Create Admin Account") {
                showAdminCreation = true
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.horizontal, AppSpacing.lg)
        .sheet(isPresented: $showAdminCreation) {
            AdminCreationView()
        }
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

struct AdminCreationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                VStack(spacing: AppSpacing.md) {
                    Text("Create Admin Account")
                        .font(AppTypography.h3)
                        .foregroundColor(Color.appTextPrimary)
                    
                    Text("Create the first admin user for the system")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.md) {
                        AppTextField(
                            title: "First Name",
                            placeholder: "Enter first name",
                            text: $firstName
                        )
                        
                        AppTextField(
                            title: "Last Name",
                            placeholder: "Enter last name",
                            text: $lastName
                        )
                    }
                    
                    AppTextField(
                        title: "Email",
                        placeholder: "Enter admin email",
                        text: $email
                    )
                    
                    AppTextField(
                        title: "Password",
                        placeholder: "Enter admin password",
                        text: $password,
                        isSecure: true
                    )
                    
                    AppTextField(
                        title: "Confirm Password",
                        placeholder: "Confirm admin password",
                        text: $confirmPassword,
                        isSecure: true
                    )
                }
                
                AppButton(
                    title: "Create Admin Account",
                    action: handleAdminCreation,
                    isLoading: isLoading
                )
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .navigationTitle("Admin Creation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(TextButtonStyle())
                }
            }
        }
    }
    
    private func handleAdminCreation() {
        guard !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword else { return }
        
        isLoading = true
        
        Task {
            let success = await authManager.createAdmin(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
            isLoading = false
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthManager.shared)
}

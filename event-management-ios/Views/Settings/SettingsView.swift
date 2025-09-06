import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var showingLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AppSpacing.md) {
                Text("Account Settings")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                    .fontWeight(.bold)
                
                Text("Manage your account information and security settings")
                    .font(AppTypography.body2)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppSpacing.lg)
            .padding(.horizontal, AppSpacing.lg)
            
            // Tab Navigation
            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person")
                            .font(.system(size: 20))
                        Text("Profile")
                            .font(AppTypography.body1)
                            .fontWeight(selectedTab == 0 ? .bold : .regular)
                    }
                    .foregroundColor(selectedTab == 0 ? Color.appTextPrimary : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                }
                
                Button(action: { selectedTab = 1 }) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "lock")
                            .font(.system(size: 20))
                        Text("Password")
                            .font(AppTypography.body1)
                            .fontWeight(selectedTab == 1 ? .bold : .regular)
                    }
                    .foregroundColor(selectedTab == 1 ? Color.appTextPrimary : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            
            // Tab Content
            if selectedTab == 0 {
                ProfileSettingsView()
            } else {
                PasswordSettingsView()
            }
            
            Spacer()
            
            // Logout Button
            Button("Logout") {
                showingLogoutAlert = true
            }
            .buttonStyle(DestructiveButtonStyle())
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task {
                    await authManager.logout()
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// MARK: - Profile Settings View
struct ProfileSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileSettingsViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Profile Information Section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Image(systemName: "person")
                            .font(.system(size: 20))
                            .foregroundColor(Color.appTextPrimary)
                        
                        Text("Profile Information")
                            .font(AppTypography.h5)
                            .foregroundColor(Color.appTextPrimary)
                            .fontWeight(.bold)
                    }
                    
                    VStack(spacing: AppSpacing.md) {
                        AppTextField(
                            title: "First Name",
                            placeholder: "Enter your first name",
                            text: $viewModel.firstName
                        )
                        
                        AppTextField(
                            title: "Last Name",
                            placeholder: "Enter your last name",
                            text: $viewModel.lastName
                        )
                        
                        AppTextField(
                            title: "Email",
                            placeholder: "Enter your email",
                            text: $viewModel.email
                        )
                        .disabled(true)
                        .foregroundColor(Color.appTextSecondary)
                    }
                }
                .padding(AppSpacing.lg)
                .background(Color.appSurface)
                .cornerRadius(AppCornerRadius.large)
                .appShadow(AppShadows.small)
                
                // Save Button
                AppButton(
                    title: "Save Changes",
                    action: {
                        Task {
                            await viewModel.updateProfile()
                            if viewModel.showSuccess {
                                showingSuccessAlert = true
                            }
                        }
                    },
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isValid
                )
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(AppTypography.caption)
                        .padding(.horizontal)
                }
            }
            .padding(AppSpacing.lg)
        }
        .onAppear {
            viewModel.loadUserProfile()
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your profile has been updated successfully.")
        }
    }
}

// MARK: - Password Settings View
struct PasswordSettingsView: View {
    @StateObject private var viewModel = SecuritySettingsViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Change Password Section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Image(systemName: "lock")
                            .font(.system(size: 20))
                            .foregroundColor(Color.appTextPrimary)
                        
                        Text("Change Password")
                            .font(AppTypography.h5)
                            .foregroundColor(Color.appTextPrimary)
                            .fontWeight(.bold)
                    }
                    
                    VStack(spacing: AppSpacing.md) {
                        AppTextField(
                            title: "Current Password",
                            placeholder: "Enter current password",
                            text: $viewModel.currentPassword,
                            isSecure: true
                        )
                        
                        AppTextField(
                            title: "New Password",
                            placeholder: "Enter new password",
                            text: $viewModel.newPassword,
                            isSecure: true
                        )
                        
                        AppTextField(
                            title: "Confirm New Password",
                            placeholder: "Confirm new password",
                            text: $viewModel.confirmPassword,
                            isSecure: true
                        )
                    }
                }
                .padding(AppSpacing.lg)
                .background(Color.appSurface)
                .cornerRadius(AppCornerRadius.large)
                .appShadow(AppShadows.small)
                
                // Update Password Button
                AppButton(
                    title: "Update Password",
                    action: {
                        Task {
                            await viewModel.updatePassword()
                            if viewModel.showSuccess {
                                showingSuccessAlert = true
                                viewModel.clearForm()
                            }
                        }
                    },
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isValid
                )
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(AppTypography.caption)
                        .padding(.horizontal)
                }
            }
            .padding(AppSpacing.lg)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your password has been updated successfully.")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}

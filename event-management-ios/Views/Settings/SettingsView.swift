import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Content
                if selectedTab == 0 {
                    ProfileSettingsView()
                } else if selectedTab == 1 {
                    SecuritySettingsView()
                } else if selectedTab == 2 {
                    PreferencesSettingsView()
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Logout") {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                }
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
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // User Avatar and Info
            VStack(spacing: 12) {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(authManager.currentUser?.firstName.prefix(1) ?? "U")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 4) {
                    Text("\(authManager.currentUser?.firstName ?? "") \(authManager.currentUser?.lastName ?? "")")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(authManager.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)
            
            // Tab Picker
            HStack {
                Button("Profile") {
                    selectedTab = 0
                }
                .foregroundColor(selectedTab == 0 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 0 ? Color.blue : Color.clear)
                .cornerRadius(8)
                
                Button("Security") {
                    selectedTab = 1
                }
                .foregroundColor(selectedTab == 1 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 1 ? Color.blue : Color.clear)
                .cornerRadius(8)
                
                Button("Preferences") {
                    selectedTab = 2
                }
                .foregroundColor(selectedTab == 2 ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == 2 ? Color.blue : Color.clear)
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Color.white.opacity(0.95))
    }
}

// MARK: - Profile Settings View

struct ProfileSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileSettingsViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 16) {
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
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
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
                    style: .primary,
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isValid
                )
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
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

// MARK: - Security Settings View

struct SecuritySettingsView: View {
    @StateObject private var viewModel = SecuritySettingsViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Change Password Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Change Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 16) {
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
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
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
                    style: .primary,
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isValid
                )
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your password has been updated successfully.")
        }
    }
}

// MARK: - Preferences Settings View

struct PreferencesSettingsView: View {
    @StateObject private var viewModel = PreferencesSettingsViewModel()
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Notification Preferences
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notification Preferences")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Toggle("Event Reminders", isOn: $viewModel.eventReminders)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Toggle("Group Updates", isOn: $viewModel.groupUpdates)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Toggle("Email Notifications", isOn: $viewModel.emailNotifications)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Toggle("Push Notifications", isOn: $viewModel.pushNotifications)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Privacy Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Toggle("Show Profile to Others", isOn: $viewModel.showProfileToOthers)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Toggle("Allow Event Invites", isOn: $viewModel.allowEventInvites)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Toggle("Show Email to Group Members", isOn: $viewModel.showEmailToGroupMembers)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Save Preferences Button
                AppButton(
                    title: "Save Preferences",
                    action: {
                        Task {
                            await viewModel.savePreferences()
                            if viewModel.showSuccess {
                                showingSuccessAlert = true
                            }
                        }
                    },
                    style: .primary,
                    isLoading: viewModel.isLoading
                )
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .onAppear {
            viewModel.loadPreferences()
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your preferences have been saved successfully.")
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthManager.shared)
    }
}

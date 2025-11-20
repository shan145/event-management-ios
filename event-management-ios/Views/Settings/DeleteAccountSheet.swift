import SwiftUI

struct DeleteAccountSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DeleteAccountViewModel()
    @State private var showingConfirmAlert = false
    
    private var userEmail: String {
        authManager.currentUser?.email ?? ""
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Delete your account", systemImage: "exclamationmark.triangle.fill")
                            .font(AppTypography.h4)
                            .foregroundColor(.red)
                        
                        Text("This action permanently removes your account, device tokens, and history. You will be removed from all groups and events.")
                            .font(AppTypography.body2)
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .padding()
                    .background(Color.appSurface)
                    .cornerRadius(AppCornerRadius.large)
                    .appShadow(AppShadows.small)
                    
                    VStack(spacing: AppSpacing.md) {
                        AppTextField(
                            title: "Current Password",
                            placeholder: "Enter current password",
                            text: $viewModel.currentPassword,
                            isSecure: true
                        )
                        
                        AppTextField(
                            title: "Type your email to confirm",
                            placeholder: userEmail.isEmpty ? "you@example.com" : userEmail,
                            text: $viewModel.confirmationEmail
                        )
                        
                        Text("Enter \(userEmail.isEmpty ? "your email" : userEmail) to confirm deletion.")
                            .font(AppTypography.caption)
                            .foregroundColor(Color.appTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.appSurface)
                    .cornerRadius(AppCornerRadius.large)
                    .appShadow(AppShadows.small)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        showingConfirmAlert = true
                    } label: {
                        Text(viewModel.isProcessing ? "Deleting..." : "Delete my account")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(UniformButtonStyle(isDestructive: true))
                    .disabled(viewModel.isProcessing || userEmail.isEmpty || !viewModel.canSubmit(expectedEmail: userEmail))
                }
                .padding()
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            viewModel.reset()
        }
        .alert("Delete your account?", isPresented: $showingConfirmAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteAccount(using: authManager) {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
}

#Preview {
    DeleteAccountSheet()
        .environmentObject(AuthManager.shared)
}


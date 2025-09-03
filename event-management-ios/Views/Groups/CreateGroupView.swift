import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateGroupViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            if AuthManager.shared.currentUser?.canCreateGroups == true {
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Group Details Section
                        groupDetailsSection
                        
                        // Description Section
                        descriptionSection
                        
                        // Spacer for bottom padding
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.xl)
                }
                .background(Color.appBackground)
            } else {
                // Access denied view
                VStack(spacing: AppSpacing.xl) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 64))
                        .foregroundColor(Color.appTextSecondary)
                    
                    Text("Access Denied")
                        .font(AppTypography.h3)
                        .foregroundColor(Color.appTextPrimary)
                    
                    Text("Only super admins can create groups")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
            }
        }
        .background(Color.appBackground)
        .ignoresSafeArea(.container, edges: .bottom)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(TextButtonStyle())
                
                Spacer()
                
                Text("Create Group")
                    .font(AppTypography.h3)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Button("Create") {
                    Task {
                        await viewModel.createGroup()
                        if viewModel.isSuccess {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isFormValid || viewModel.isLoading || AuthManager.shared.currentUser?.canCreateGroups != true)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            
            Divider()
        }
        .background(Color.appSurface)
    }
    
    private var groupDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Group Details")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextField(
                title: "Group Name",
                placeholder: "Enter group name",
                text: $viewModel.name
            )
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Description")
                .font(AppTypography.h4)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextArea(
                title: "Group Description",
                placeholder: "Enter group description (optional)",
                text: $viewModel.description
            )
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
}

#Preview {
    CreateGroupView()
}

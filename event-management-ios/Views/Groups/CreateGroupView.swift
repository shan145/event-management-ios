import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateGroupViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Group Details Section
                    groupDetailsSection
                    
                    // Description Section
                    descriptionSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle("Create Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createGroup()
                            if viewModel.isSuccess {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var groupDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Group Details")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextField(
                title: "Group Name",
                placeholder: "Enter group name",
                text: $viewModel.name
            )
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Description")
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            AppTextArea(
                title: "Group Description",
                placeholder: "Enter group description (optional)",
                text: $viewModel.description
            )
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .cornerRadius(AppCornerRadius.large)
        .appShadow(AppShadows.small)
    }
}

#Preview {
    CreateGroupView()
}

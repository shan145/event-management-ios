import SwiftUI

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JoinGroupViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(Color.appPrimary)
                    
                    Text("Join a Group")
                        .font(AppTypography.h3)
                        .foregroundColor(Color.appTextPrimary)
                    
                    Text("Enter the group code to join an existing group")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xxl)
                
                // Join Form
                VStack(spacing: AppSpacing.lg) {
                    AppTextField(
                        title: "Group Code",
                        placeholder: "Enter group code",
                        text: $viewModel.groupCode
                    )
                    
                    AppButton(
                        title: "Join Group",
                        action: {
                            Task {
                                await viewModel.joinGroup()
                                if viewModel.isSuccess {
                                    dismiss()
                                }
                            }
                        },
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isFormValid
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
            }
            .background(Color.appBackground)
            .navigationTitle("Join Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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
}

#Preview {
    JoinGroupView()
}

import SwiftUI

struct InviteLinkView: View {
    let inviteToken: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InviteLinkViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView()
                } else if let group = viewModel.group {
                    ScrollView {
                        VStack(spacing: AppSpacing.xl) {
                            // Group Info Card
                            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                                VStack(alignment: .leading, spacing: AppSpacing.md) {
                                    Text(group.name)
                                        .font(AppTypography.h3)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.appTextPrimary)
                                    
                                    if let tags = group.tags, !tags.isEmpty {
                                        HStack(spacing: AppSpacing.sm) {
                                            ForEach(tags, id: \.self) { tag in
                                                Text(tag)
                                                    .font(AppTypography.caption)
                                                    .padding(.horizontal, AppSpacing.sm)
                                                    .padding(.vertical, AppSpacing.xs)
                                                    .background(Color.appPrimary.opacity(0.1))
                                                    .foregroundColor(Color.appPrimary)
                                                    .cornerRadius(AppCornerRadius.small)
                                            }
                                        }
                                    }
                                    
                                    if let memberCount = group.members?.count {
                                        HStack {
                                            Image(systemName: "person.3.fill")
                                                .foregroundColor(Color.appTextSecondary)
                                            Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                                                .font(AppTypography.body2)
                                                .foregroundColor(Color.appTextSecondary)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                if viewModel.isSuccess {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Successfully joined the group!")
                                            .font(AppTypography.body1)
                                            .foregroundColor(.green)
                                    }
                                } else if viewModel.showError, let errorMessage = viewModel.errorMessage {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(errorMessage)
                                            .font(AppTypography.body2)
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    AppButton(
                                        title: "Join Group",
                                        action: {
                                            Task {
                                                await viewModel.joinGroup(token: inviteToken)
                                                if viewModel.isSuccess {
                                                    // Dismiss after a short delay
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                        NavigationCoordinator.shared.clearPendingInvite()
                                                        dismiss()
                                                    }
                                                }
                                            }
                                        },
                                        isLoading: viewModel.isJoining,
                                        isDisabled: viewModel.isJoining || viewModel.isSuccess
                                    )
                                }
                            }
                            .padding(AppSpacing.lg)
                            .background(Color.appSurface)
                            .cornerRadius(AppCornerRadius.large)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.lg)
                        }
                    }
                } else if viewModel.showError {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.red)
                        
                        Text("Invalid Invite Link")
                            .font(AppTypography.h4)
                            .foregroundColor(Color.appTextPrimary)
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(AppTypography.body2)
                                .foregroundColor(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.lg)
                        }
                        
                        Button("Close") {
                            NavigationCoordinator.shared.clearPendingInvite()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, AppSpacing.md)
                    }
                    .padding(AppSpacing.xl)
                }
            }
            .navigationTitle("Group Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        NavigationCoordinator.shared.clearPendingInvite()
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadGroupInfo(token: inviteToken)
        }
    }
}

@MainActor
class InviteLinkViewModel: ObservableObject {
    @Published var group: Group?
    @Published var isLoading = false
    @Published var isJoining = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let apiService = APIService.shared
    
    func loadGroupInfo(token: String) async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let response = try await apiService.getGroupFromInvite(token: token)
            group = response.data.group
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func joinGroup(token: String) async {
        guard let userId = AuthManager.shared.currentUser?.id else {
            errorMessage = "You must be logged in to join a group"
            showError = true
            return
        }
        
        isJoining = true
        errorMessage = nil
        showError = false
        
        do {
            _ = try await apiService.joinGroup(token: token, userId: userId)
            isSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isJoining = false
    }
}


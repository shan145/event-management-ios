import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                HStack {
                    Text("My Groups")
                        .font(AppTypography.h4)
                        .foregroundColor(Color.appTextPrimary)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(viewModel.myGroups.count) group\(viewModel.myGroups.count == 1 ? "" : "s")")
                        .font(AppTypography.body2)
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                
                // Groups List
                if viewModel.isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else if viewModel.myGroups.isEmpty {
                    emptyStateView(
                        icon: "person.3",
                        title: "No groups yet",
                        message: "Join a group to start managing events"
                    )
                } else {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(viewModel.myGroups) { group in
                            DashboardGroupCardView(group: group) {
                                Task { await viewModel.loadDashboardData() }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
        .background(Color.appBackground)
        .task {
            await viewModel.loadDashboardData()
        }
        .refreshable {
            await viewModel.loadDashboardData()
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.appTextSecondary)
            
            Text(title)
                .font(AppTypography.h5)
                .foregroundColor(Color.appTextPrimary)
            
            Text(message)
                .font(AppTypography.body2)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }
}

#Preview {
    GroupsView()
        .environmentObject(AuthManager.shared)
}
